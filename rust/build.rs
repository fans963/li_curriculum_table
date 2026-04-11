use burn_onnx::ModelGen;
use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=../assets/models/common_pruned.onnx");
    
    ModelGen::new()
        .input("../assets/models/common_pruned.onnx")
        .out_dir("model/")
        .development(true)
        .run_from_script();

    // --- Compression Step ---
    let out_dir = env::var("OUT_DIR").expect("OUT_DIR not set");
    let model_dir = Path::new(&out_dir).join("model");
    let bpk_path = model_dir.join("common_pruned.bpk");
    let zstd_path = model_dir.join("common_pruned.bpk.zstd");

    if bpk_path.exists() {
        let data = fs::read(&bpk_path).expect("Failed to read model .bpk file");
        // Use compression level 10 for a good size/time tradeoff for static binaries
        let compressed = zstd::encode_all(&data[..], 10).expect("Failed to compress model with zstd");
        fs::write(&zstd_path, compressed).expect("Failed to write compressed model .bpk.zstd");
        
        let original_size = data.len();
        let compressed_size = fs::metadata(&zstd_path).map(|m| m.len()).unwrap_or(0);
        println!(
            "cargo:warning=Model compression: {} KB -> {} KB ({:.1}% reduction)",
            original_size / 1024,
            compressed_size / 1024,
            (1.0 - (compressed_size as f64 / original_size as f64)) * 100.0
        );
    }
}
