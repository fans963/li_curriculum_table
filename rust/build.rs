use burn_onnx::ModelGen;
use burn_store::{BurnpackStore, BurnpackWriter, ModuleStore, TensorSnapshot};
use burn::tensor::{DType};
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
    let zstd_path = model_dir.join("common_pruned.bpk.zstd");

    // Note: No rs_path patching of DType::F32 -> DType::F16. 
    // We want the runtime to be F32 to avoid "matmul: dtype mismatch" in burn-flex.

    // --- 3. Weight Quantization (Manual F32 -> F16 for storage) ---
    if bpk_path.exists() {
        let mut store = BurnpackStore::from_file(&bpk_path);
        let snapshots = store.get_all_snapshots().expect("Failed to get snapshots from BPK");
        
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
        let quantized_bpk_bytes = writer.to_bytes().expect("Failed to serialize quantized Burnpack");
        let quantized_bpk: &[u8] = quantized_bpk_bytes.as_ref();

        // --- 4. Compression ---
        let compressed =
            zstd::encode_all(quantized_bpk, 12).expect("Failed to compress model");
        fs::write(&zstd_path, &compressed).expect("Failed to write compressed bpk.zstd");

        println!(
            "cargo:warning=OCR Optimization [F16-Storage + Zstd]: {} KB -> {} KB -> {} KB (Total Reduction: {:.1}%)",
            fs::metadata(&bpk_path).unwrap().len() / 1024,
            quantized_bpk.len() / 1024,
            compressed.len() / 1024,
            (1.0 - (compressed.len() as f64 / fs::metadata(&bpk_path).unwrap().len() as f64)) * 100.0
        );
    }
}
