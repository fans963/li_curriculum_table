use crate::model::captcha_ocr::Model;
use burn::prelude::*;
use burn_flex::Flex;
use burn_store::ModuleSnapshot;
use image::GenericImageView;

const MODEL_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/model/captcha_ocr.bpk"));

// Universal backend: Flex (Fast & Portable CPU)
type B = Flex;
type Dev = <B as burn::tensor::backend::BackendTypes>::Device;

// Captcha OCR config
const IMG_HEIGHT: u32 = 22;
const IMG_WIDTH: u32 = 62;
const NUM_CHARS: usize = 4;
const CHARSET: &str = "0123456789abcdefghijklmnopqrstuvwxyz";

pub struct DdddOcr {
    model: Model<B>,
    device: Dev,
}

impl Default for DdddOcr {
    fn default() -> Self {
        Self::new()
    }
}

impl DdddOcr {
    pub fn new() -> Self {
        let device = Default::default();

        let mut store = burn_store::BurnpackStore::from_bytes(Some(
            burn::tensor::Bytes::from_bytes_vec(MODEL_BYTES.to_vec()),
        ));

        let mut model = Model::new(&device);
        model
            .load_from(&mut store)
            .expect("Failed to load captcha OCR model from bytes");

        Self { model, device }
    }

    pub fn recognize(&self, img_bytes: &[u8]) -> String {
        let img = image::load_from_memory(img_bytes).unwrap();

        // Resize to model's expected input size (22x62)
        let img = img.resize_exact(IMG_WIDTH, IMG_HEIGHT, image::imageops::FilterType::Lanczos3);

        let (width, height) = img.dimensions();
        let img_gray = img.grayscale();

        // Build grayscale tensor: (1, 1, H, W) with normalization to [0, 1]
        let mut pixels: Vec<f32> = Vec::with_capacity((width * height) as usize);
        for y in 0..height {
            for x in 0..width {
                let pixel = img_gray.get_pixel(x, y);
                pixels.push(pixel[0] as f32 / 255.0);
            }
        }

        let data =
            burn::tensor::TensorData::new(pixels, vec![1, 1, height as usize, width as usize]);
        let tensor = Tensor::<B, 4>::from_data(data, &self.device);

        // Forward pass: output is (1, 4, 36) — 4 characters, 36 classes each
        let logits = self.model.forward(tensor);

        // Decode: argmax per character position
        let data = logits.into_data();
        let values: Vec<f32> = data.to_vec::<f32>().expect("Failed to convert to Vec<f32>");

        let alphabet_len = CHARSET.len();
        let charset_chars: Vec<char> = CHARSET.chars().collect();
        let mut result = String::new();

        for char_idx in 0..NUM_CHARS {
            let offset = char_idx * alphabet_len;
            if offset + alphabet_len > values.len() {
                break;
            }

            // Find the character with highest probability
            let mut best_idx = 0;
            let mut best_val = f32::MIN;
            for (i, &val) in values[offset..offset + alphabet_len].iter().enumerate() {
                if val > best_val {
                    best_val = val;
                    best_idx = i;
                }
            }

            result.push(charset_chars[best_idx]);
        }

        result
    }
}
