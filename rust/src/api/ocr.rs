use image::{DynamicImage, GenericImageView};
use tract_onnx::prelude::*;
use std::io::Cursor;

pub struct DdddOcr {
    model: RunnableModel<TypedFact, Box<dyn TypedOp>, Graph<TypedFact, Box<dyn TypedOp>>>,
    charset: Vec<String>,
}

impl DdddOcr {
    pub fn new(model_bytes: Vec<u8>) -> anyhow::Result<DdddOcr> {
        println!("OCR: Initializing from external bytes (len: {})...", model_bytes.len());
        let mut model_cursor = Cursor::new(model_bytes);
        println!("OCR: Initializing tract engine (this may take a few seconds on Web)...");
        let model = tract_onnx::onnx()
            .model_for_read(&mut model_cursor)?
            .into_optimized()?
            .into_runnable()?;

        let charset = vec![
            "", "6", "f", "p", "L", "Y", "w", "3", "F", "m", "X", "G", "x", "i", "T", "N", "v", "c", "B", "n", "Q", "H", "K", "W", "P", "r", "l", "E", "Z", "s", "2", "z", "D", "O", "4", "1", "t", "b", "o", "u", "9", "j", "0", "8", "5", "e", "A", "R", "g", "k", "S", "I", "7", "d", "V", "J", "a", "h", "q", "U", "M", "y", "C"
        ].into_iter().map(|s| s.to_string()).collect();

        println!("OCR: Model ready.");
        Ok(Self { model, charset })
    }

    #[flutter_rust_bridge::frb(ignore)]
    fn preprocess(&self, img: DynamicImage) -> DynamicImage {
        let (w, h) = img.dimensions();
        let target_h = 64;
        let target_w = (w as f32 * (target_h as f32 / h as f32)).round() as u32;
        
        img.resize_exact(target_w, target_h, image::imageops::FilterType::CatmullRom)
    }

    #[flutter_rust_bridge::frb(ignore)]
    pub fn classification(&self, img: DynamicImage) -> anyhow::Result<String> {
        let resized = self.preprocess(img);
        let (width, height) = resized.dimensions();
        let rgb8 = resized.into_rgb8();
        
        let mut data = Vec::with_capacity((width * height) as usize);
        for pixel in rgb8.pixels() {
            let r = pixel[0] as f32;
            let g = pixel[1] as f32;
            let b = pixel[2] as f32;
            let val = r * 0.299 + g * 0.587 + b * 0.114;
            data.push((val / 127.5) - 1.0);
        }

        let tensor = tract_ndarray::Array4::from_shape_vec((1, 1, height as usize, width as usize), data)
            .unwrap()
            .into_tensor();

        let result = self.model.run(tvec!(tensor.into()))?;
        
        let output = result[0].to_array_view::<f32>()?;
        Ok(self.decode_ctc(&output))
    }

    fn decode_ctc(&self, output: &tract_ndarray::ArrayViewD<f32>) -> String {
        println!("Output shape: {:?}", output.shape());
        
        // Find which axes are batch, time, class. 
        // Typically output is [batch, time, class] or [time, batch, class]
        // From burn we saw [23, 1, 63] meaning [time, batch, class].
        // Let's assume the highest size dimension (after class) is time.
        // Actually, ddddocr is usually [1, 23, 63] in tract if the onnx is standard, 
        // or [23, 1, 63]. We can just dynamically find the time and class axes.
        
        let shape = output.shape();
        let class_axis = shape.iter().position(|&d| d == 73).unwrap_or_else(|| shape.len() - 1);
        let mut non_class = vec![0, 1, 2];
        non_class.retain(|&x| x != class_axis);
        
        let time_axis = if shape[non_class[0]] > shape[non_class[1]] { non_class[0] } else { non_class[1] };
        let seq_len = shape[time_axis];
        let classes = shape[class_axis];
        
        // Argmax along class_axis for each time step
        let mut indices_vec = Vec::new();
        
        for t in 0..seq_len {
            let mut best_val = f32::NEG_INFINITY;
            let mut best_idx = 0;
            for c in 0..classes {
                // Determine indices based on shape [time, batch, class] vs [batch, time, class]
                let mut idx = vec![0; 3];
                idx[time_axis] = t;
                idx[class_axis] = c;
                // batch axis defaults to 0
                
                let val = output[idx.as_slice()];
                if val > best_val {
                    best_val = val;
                    best_idx = c;
                }
            }
            indices_vec.push(best_idx);
        }

        println!("Indices: {:?}", indices_vec);

        let mut result = String::new();
        let mut last_idx = 0; // Blank is 0

        for &idx in indices_vec.iter() {
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
