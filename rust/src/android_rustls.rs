// JNI entrypoint used by MainActivity to initialize the Android certificate
// verifier before any reqwest/rustls request is made.
//
// This symbol is kept intentionally out of `crate::api` because it is called
// from Kotlin, not from flutter_rust_bridge.

use jni::errors::ThrowRuntimeExAndDefault;
use jni::objects::JObject;
use jni::EnvUnowned;

#[unsafe(no_mangle)]
pub extern "system" fn Java_com_example_curriculum_1table_MainActivity_initRustlsPlatformVerifier(
    raw_env: *mut jni::sys::JNIEnv,
    raw_context: jni::sys::jobject,
) {
    let mut env = unsafe { EnvUnowned::from_raw(raw_env) };
    let outcome = env.with_env(|env| {
        let context = unsafe { JObject::from_raw(env, raw_context) };
        rustls_platform_verifier::android::init_with_env(env, context)
    });

    outcome.resolve::<ThrowRuntimeExAndDefault>();
}
