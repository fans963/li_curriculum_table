package com.example.curriculum_table

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    init {
        System.loadLibrary("rust_lib_li_curriculum_table")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initRustlsPlatformVerifier(applicationContext)
    }

    private external fun initRustlsPlatformVerifier(context: Context)
}
