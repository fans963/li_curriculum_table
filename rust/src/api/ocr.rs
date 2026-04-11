use image::{DynamicImage, GenericImageView};
use log::info;
use std::io::Cursor;
use std::sync::Mutex;
use tract_onnx::prelude::*;

enum OcrEngine {
    Tract(RunnableModel<TypedFact, Box<dyn TypedOp>, Graph<TypedFact, Box<dyn TypedOp>>>),
}

pub struct DdddOcr {
    engine: Mutex<OcrEngine>,
    charset: Vec<String>,
}

impl DdddOcr {
    pub fn new(model_bytes: Vec<u8>) -> anyhow::Result<DdddOcr> {
        info!("OCR: Initializing optimized engine...");

        let charset = vec![
            "", "6", "f", "p", "L", "Y", "w", "3", "F", "m", "X", "G", "x", "i", "T", "N", "v",
            "c", "B", "n", "Q", "H", "K", "W", "P", "r", "l", "E", "Z", "s", "2", "z", "D", "O",
            "4", "1", "t", "b", "o", "u", "9", "j", "0", "8", "5", "e", "A", "R", "g", "k", "S",
            "I", "7", "d", "V", "J", "a", "h", "q", "U", "M", "y", "C",
        ]
        .into_iter()
        .map(|s| s.to_string())
        .collect();

        info!("OCR: [v5] Precision: f32 (Optimized), Target Shape: [1, 1, 64, 192]");
        let mut model_cursor = Cursor::new(model_bytes);
        let model = tract_onnx::onnx()
            .model_for_read(&mut model_cursor)?
            .with_input_fact(0, f32::fact(&[1, 1, 64, 192]).into())?
            .into_typed()?
            .into_optimized()?
            .into_runnable()?;

        info!("OCR: [v5] Optimized Tract Engine initialized.");
        Ok(Self {
            engine: Mutex::new(OcrEngine::Tract(model)),
            charset,
        })
    }

    #[flutter_rust_bridge::frb(ignore)]
    fn preprocess(&self, img: DynamicImage) -> (u32, u32, Vec<f32>) {
        let (w, h) = img.dimensions();
        let target_h = 64;
        let target_w_actual = (w as f32 * (target_h as f32 / h as f32)).round() as u32;
        let target_w_fixed = 192;

        let resized = img.resize_exact(
            target_w_actual,
            target_h,
            image::imageops::FilterType::CatmullRom,
        );
        let rgb8 = resized.into_rgb8();

        // Use 1.0 for padding (white background in normalized space)
        let mut data = vec![1.0f32; (target_w_fixed * target_h) as usize];

        for y in 0..target_h {
            for x in 0..target_w_actual.min(target_w_fixed) {
                let pixel = rgb8.get_pixel(x, y);
                let r = pixel[0] as f32;
                let g = pixel[1] as f32;
                let b = pixel[2] as f32;
                let val = r * 0.299 + g * 0.587 + b * 0.114;
                data[(y * target_w_fixed + x) as usize] = (val / 127.5) - 1.0;
            }
        }

        (target_w_fixed, target_h, data)
    }

    #[flutter_rust_bridge::frb(ignore)]
    pub fn classification(&self, img: DynamicImage) -> anyhow::Result<String> {
        let (width, height, data) = self.preprocess(img);

        let engine = self
            .engine
            .lock()
            .map_err(|_| anyhow::anyhow!("Failed to lock OCR engine"))?;

        match &*engine {
            OcrEngine::Tract(model) => {
                let tensor = tract_ndarray::Array4::from_shape_vec(
                    (1, 1, height as usize, width as usize),
                    data,
                )
                .map_err(|e| anyhow::anyhow!("Failed to create tensor: {}", e))?
                .into_tensor();

                let result = model.run(tvec!(tensor.into()))?;
                let output = result[0].to_array_view::<f32>()?;
                Ok(self.decode_ctc(&output))
            }
        }
    }

    fn decode_ctc(&self, output: &tract_ndarray::ArrayViewD<f32>) -> String {
        let shape = output.shape();
        let class_axis = shape
            .iter()
            .position(|&d| d == 73)
            .unwrap_or_else(|| shape.len() - 1);
        let mut non_class = vec![0, 1, 2];
        non_class.retain(|&x| x != class_axis);

        let time_axis = if shape[non_class[0]] > shape[non_class[1]] {
            non_class[0]
        } else {
            non_class[1]
        };
        let seq_len = shape[time_axis];
        let classes = shape[class_axis];

        let mut indices_vec = Vec::new();
        for t in 0..seq_len {
            let mut best_val = f32::NEG_INFINITY;
            let mut best_idx = 0;
            for c in 0..classes {
                let mut idx_raw = vec![0; 3];
                idx_raw[time_axis] = t;
                idx_raw[class_axis] = c;

                let idx = tract_ndarray::IxDyn(&idx_raw);
                let val = output[idx];
                if val > best_val {
                    best_val = val;
                    best_idx = c;
                }
            }
            indices_vec.push(best_idx);
        }

        self.indices_to_string(indices_vec)
    }

    fn indices_to_string(&self, indices: Vec<usize>) -> String {
        let mut result = String::new();
        let mut last_idx = 0;
        for &idx in indices.iter() {
            if idx == 0 {
                last_idx = 0;
                continue;
            }
            if idx == last_idx {
                continue;
            }
            if idx > 0 && idx < self.charset.len() {
                result.push_str(&self.charset[idx]);
            }
            last_idx = idx;
        }
        result
    }
}
