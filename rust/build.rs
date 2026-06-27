use burn_onnx::ModelGen;
use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=../assets/models/captcha_ocr.onnx");

    // Generate model code from ONNX
    ModelGen::new()
        .input("../assets/models/captcha_ocr.onnx")
        .out_dir("model/")
        .development(true)
        .run_from_script();

    let out_dir = env::var("OUT_DIR").expect("OUT_DIR not set");
    let model_dir = Path::new(&out_dir).join("model");
    let bpk_path = model_dir.join("captcha_ocr.bpk");

    if bpk_path.exists() {
        let size = fs::metadata(&bpk_path).unwrap().len();
        println!("cargo:warning=Captcha OCR Model: {} KB", size / 1024);
    }
}
