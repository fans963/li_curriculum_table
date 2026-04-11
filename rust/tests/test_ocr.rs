#[cfg(test)]
mod tests {
    use std::fs;
    use rust_lib_li_curriculum_table::ocr::DdddOcr;

    #[test]
    fn test_ocr_recognition() {
        let ocr = DdddOcr::new();
        
        let img_bytes = fs::read("tests/verifycode.jpg").unwrap();
        let result = ocr.recognize(&img_bytes);
        println!("verifycode.jpg: {}", result);

        let img_bytes = fs::read("tests/verifycode1.jpg").unwrap();
        let result = ocr.recognize(&img_bytes);
        println!("verifycode1.jpg: {}", result);

        let img_bytes = fs::read("tests/verifycode2.jpg").unwrap();
        let result = ocr.recognize(&img_bytes);
        println!("verifycode2.jpg: {}", result);
    }
}
