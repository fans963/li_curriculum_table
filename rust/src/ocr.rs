use crate::model::common_pruned::Model;
use burn::prelude::*;
use burn_flex::Flex;
use image::GenericImageView;

const COMPRESSED_MODEL_BYTES: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/model/common_pruned.bpk.zstd"));

// Universal backend: Flex (Fast & Portable CPU)
type B = Flex;
type Dev = <B as Backend>::Device;

pub struct DdddOcr {
    model: Model<B>,
    device: Dev,
}

impl DdddOcr {
    pub fn new() -> Self {
        use burn_store::ModuleSnapshot;
        use std::io::Read;
        let device = Default::default();

        // Decompress F16 model weights at runtime
        let mut decoder =
            ruzstd::decoding::StreamingDecoder::new(std::io::Cursor::new(COMPRESSED_MODEL_BYTES))
                .expect("Failed to initialize zstd decoder");
        let mut decompressed = Vec::new();
        decoder
            .read_to_end(&mut decompressed)
            .expect("Failed to decompress OCR model weights");

        // Load F16 weights and cast back to F32 for Flex backend compatibility
        let mut store = burn_store::BurnpackStore::from_bytes(Some(
            burn::tensor::Bytes::from_bytes_vec(decompressed),
        ));
        
        // We use the HalfPrecisionAdapter to ensure F16 -> F32 conversion during load.
        // For the pruned model, we want to make sure it handles all possible weights.
        let mut adapter = burn_store::HalfPrecisionAdapter::new();
        // Add all likely module names if they are custom
        adapter = adapter.with_module("Model"); 
        
        store = store.with_from_adapter(adapter);

        let mut model = Model::new(&device);
        model
            .load_from(&mut store)
            .expect("Failed to load OCR model from bytes");

        Self { model, device }
    } 

    pub fn recognize(&self, img_bytes: &[u8]) -> String {
        let mut img = image::load_from_memory(img_bytes).unwrap();

        let aspect_ratio = img.width() as f32 / img.height() as f32;
        let new_width = (64.0 * aspect_ratio) as u32;
        img = img.resize_exact(new_width, 64, image::imageops::FilterType::Lanczos3);

        let (width, height) = img.dimensions();
        let img_gray = img.grayscale();

        let mut floats = Vec::with_capacity((width * height) as usize);
        for y in 0..height {
            for x in 0..width {
                let pixel = img_gray.get_pixel(x, y);
                // Normalization: (x / 255.0 - 0.5) / 0.5 => (x - 127.5) / 127.5
                floats.push((pixel[0] as f32 - 127.5) / 127.5);
            }
        }

        let data =
            burn::tensor::TensorData::new(floats, vec![1, 1, height as usize, width as usize]);
        let tensor = Tensor::<B, 4>::from_data(data, &self.device);

        let logits = self.model.forward(tensor);

        // CTC Greedy Decode
        let argmax = logits.argmax(2).squeeze_dim::<2>(2);
        let data = argmax.into_data();

        // Backend returns i32 for Flow-based kernels
        let indices: Vec<usize> = data
            .to_vec::<i32>()
            .expect("Failed to convert TensorData to Vec<i32>")
            .into_iter()
            .map(|x| x as usize)
            .collect();

        // Charset from common_pruned.json (pruned 63-class model)
        const CHARSET: [&str; 63] = [
            "", "6", "f", "p", "L", "Y", "w", "3", "F", "m", "X", "G", "x", "i", "T", "N", "v",
            "c", "B", "n", "Q", "H", "K", "W", "P", "r", "l", "E", "Z", "s", "2", "z", "D", "O",
            "4", "1", "t", "b", "o", "u", "9", "j", "0", "8", "5", "e", "A", "R", "g", "k", "S",
            "I", "7", "d", "V", "J", "a", "h", "q", "U", "M", "y", "C",
        ];

        let mut result = String::new();
        let mut last_idx = usize::MAX;

        for &idx in indices.iter() {
            if idx != 0 && idx != last_idx {
                if let Some(&c) = CHARSET.get(idx) {
                    result.push_str(c);
                }
            }
            last_idx = idx;
        }

        result
    }
}
