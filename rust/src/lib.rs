#![recursion_limit = "256"]

#[cfg(not(target_arch = "wasm32"))]
#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

pub mod api;
pub mod crawler;
mod frb_generated;
pub mod model;
pub mod ocr;
