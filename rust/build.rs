use burn::tensor::DType;
use burn_onnx::ModelGen;
use burn_store::{BurnpackStore, BurnpackWriter, ModuleStore, TensorSnapshot};
use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=../assets/models/common_pruned.onnx");

    // 1. Generate model code (KEEPING IT AS F32 FOR RUNTIME COMPATIBILITY)
    ModelGen::new()
        .input("../assets/models/common_pruned.onnx")
        .out_dir("model/")
        .development(true)
        .run_from_script();

    let out_dir = env::var("OUT_DIR").expect("OUT_DIR not set");
    let model_dir = Path::new(&out_dir).join("model");
    let bpk_path = model_dir.join("common_pruned.bpk");

    // Note: No rs_path patching of DType::F32 -> DType::F16.
    // We want the runtime to be F32 to avoid "matmul: dtype mismatch" in burn-flex.

    // --- 3. Weight Quantization (Manual F32 -> F16 for storage) ---
    if bpk_path.exists() {
        let original_size = fs::metadata(&bpk_path).unwrap().len();
        
        // Load the BPK from memory instead of mapping the file to avoid locking issues on Windows
        let bpk_bytes = fs::read(&bpk_path).expect("Failed to read BPK");
        let mut store = BurnpackStore::from_bytes(Some(burn::tensor::Bytes::from_bytes_vec(bpk_bytes)));
        
        let snapshots = store
            .get_all_snapshots()
            .expect("Failed to get snapshots from BPK");

        let mut quantized_snapshots = Vec::with_capacity(snapshots.len());

        for s in snapshots.values() {
            if s.dtype == DType::F32 {
                let data = s.to_data().expect("Failed to get data");
                let f16_data = data.convert::<half::f16>();

                let s_f16 = TensorSnapshot::from_data(
                    f16_data,
                    s.path_stack.clone().unwrap_or_default(),
                    s.container_stack.clone().unwrap_or_default(),
                    s.tensor_id.unwrap_or_default(),
                );
                quantized_snapshots.push(s_f16);
            } else {
                quantized_snapshots.push(s.clone());
            }
        }

        // Write the quantized snapshots to a new Burnpack binary
        let writer = BurnpackWriter::new(quantized_snapshots);
        let quantized_bpk_bytes = writer
            .to_bytes()
            .expect("Failed to serialize quantized Burnpack");
        let quantized_bpk: &[u8] = quantized_bpk_bytes.as_ref();
        let new_size = quantized_bpk.len() as u64;

        // Write the quantized BPK directly (replacing the unquantized one or creating a new one)
        fs::write(&bpk_path, quantized_bpk).expect("Failed to write quantized bpk");

        println!(
            "cargo:warning=OCR Optimization [F16-Storage]: {} KB -> {} KB (Reduction: {:.1}%)",
            original_size / 1024,
            new_size / 1024,
            (1.0 - (new_size as f64 / original_size as f64)) * 100.0
        );
    }
}
