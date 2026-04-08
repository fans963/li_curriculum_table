import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

const String kCommonModelAsset = 'model/common.onnx';
const String kCommonConfigAsset = 'model/common.json';

class DdddOcrConfig {
	DdddOcrConfig({
		required this.word,
		required this.image,
		required this.channel,
		required this.charset,
	});

	final bool word;
	final List<int> image;
	final int channel;
	final List<String> charset;

	factory DdddOcrConfig.fromJson(Map<String, dynamic> json) {
		return DdddOcrConfig(
			word: json['word'] as bool,
			image: (json['image'] as List).map((e) => (e as num).toInt()).toList(),
			channel: (json['channel'] as num).toInt(),
			charset: (json['charset'] as List).map((e) => e.toString()).toList(),
		);
	}
}

class DdddOcr {
	DdddOcr._({
		required OrtSession session,
		required DdddOcrConfig config,
		required bool diy,
	})  : _session = session,
				_config = config,
				_diy = diy;

	final OrtSession _session;
	final DdddOcrConfig _config;
	final bool _diy;
	List<int>? _alnumCharsetIndicesCache;

	static Future<DdddOcr> createFromAssets({
		String modelAsset = kCommonModelAsset,
		String configAsset = kCommonConfigAsset,
		bool diy = false,
	}) async {
		final runtime = OnnxRuntime();
		final session = await _createBundledSession(runtime, modelAsset);
		final configRaw = await rootBundle.loadString(configAsset);
		final config = DdddOcrConfig.fromJson(jsonDecode(configRaw) as Map<String, dynamic>);

		return DdddOcr._(
			session: session,
			config: config,
			diy: diy,
		);
	}

	static Future<DdddOcr> createCommon({bool diy = false}) {
		return createFromAssets(
			modelAsset: kCommonModelAsset,
			configAsset: kCommonConfigAsset,
			diy: diy,
		);
	}

	Future<String> classification(
		Uint8List imageBytes, {
		bool pngFix = false,
		bool alnumOnly = false,
	}) async {
		final decoded = img.decodeImage(imageBytes);
		if (decoded == null) {
			throw ArgumentError('invalid image bytes');
		}

		final resized = _resize(decoded);
		final width = resized.width;
		final height = resized.height;
		final channels = _config.channel;
		final inputData = _toNchwFloat32(resized, channels: channels, pngFix: pngFix);

		final input = await OrtValue.fromList(
			Float32List.fromList(inputData),
			<int>[1, channels, height, width],
		);

		try {
			if (_session.inputNames.isEmpty) {
				throw StateError('model has no input names');
			}

			final outputs = await _session.run({_session.inputNames.first: input});
			try {
				if (outputs.isEmpty) {
					throw StateError('model returned no outputs');
				}

				final outputValue = _pickPrimaryOutput(outputs);
				final raw = await outputValue.asFlattenedList();
				final data = raw.map((e) => (e as num).toDouble()).toList(growable: false);
				final shape = outputValue.shape;
				final indices = _decodeIndices(
					shape: shape,
					data: data,
					charsetLen: _config.charset.length,
					allowedClassIndices: alnumOnly ? _alnumCharsetIndices : null,
				);

				final sb = StringBuffer();
				var last = 0;
				for (final idx in indices) {
					if (idx == 0) {
						// CTC blank must reset repeat barrier: z,blank,z => zz
						last = 0;
						continue;
					}
					if (idx == last) {
						continue;
					}
					if (idx >= 0 && idx < _config.charset.length) {
						sb.write(_config.charset[idx]);
					}
					last = idx;
				}

				return sb.toString();
			} finally {
				for (final value in outputs.values) {
					await value.dispose();
				}
			}
		} finally {
			await input.dispose();
		}
	}

	Future<void> close() => _session.close();

	List<int> get _alnumCharsetIndices {
		if (_alnumCharsetIndicesCache != null) {
			return _alnumCharsetIndicesCache!;
		}

		final indices = <int>{0};
		final re = RegExp(r'^[A-Za-z0-9]$');
		for (var i = 1; i < _config.charset.length; i++) {
			if (re.hasMatch(_config.charset[i])) {
				indices.add(i);
			}
		}

		_alnumCharsetIndicesCache = indices.toList(growable: false);
		return _alnumCharsetIndicesCache!;
	}

	static Future<OrtSession> _createBundledSession(OnnxRuntime runtime, String modelAsset) async {
		return runtime.createSessionFromAsset(modelAsset);
	}

	img.Image _resize(img.Image source) {
		final resizeW = _config.image[0];
		final resizeH = _config.image[1];

		if (resizeW == -1) {
			if (_config.word) {
				return img.copyResize(source, width: resizeH, height: resizeH, interpolation: img.Interpolation.cubic);
			}
			final targetW = ((source.width * resizeH) / source.height).round().clamp(1, 10000);
			return img.copyResize(source, width: targetW, height: resizeH, interpolation: img.Interpolation.cubic);
		}

		return img.copyResize(source, width: resizeW, height: resizeH, interpolation: img.Interpolation.cubic);
	}

	List<double> _toNchwFloat32(
		img.Image source, {
		required int channels,
		required bool pngFix,
	}) {
		final width = source.width;
		final height = source.height;
		final out = List<double>.filled(channels * height * width, 0);

		img.Image working = source;
		if (channels == 1) {
			working = img.grayscale(source);
		} else if (pngFix) {
			working = _pngRgbaBlackPreprocess(source);
		}

		for (var y = 0; y < height; y++) {
			for (var x = 0; x < width; x++) {
				final p = working.getPixel(x, y);
				final r = p.r.toDouble();
				final g = p.g.toDouble();
				final b = p.b.toDouble();

				if (_diy && channels == 3) {
					out[(0 * height + y) * width + x] = ((r / 255.0) - 0.485) / 0.229;
					out[(1 * height + y) * width + x] = ((g / 255.0) - 0.456) / 0.224;
					out[(2 * height + y) * width + x] = ((b / 255.0) - 0.406) / 0.225;
				} else if (_diy && channels == 1) {
					out[(0 * height + y) * width + x] = ((r / 255.0) - 0.456) / 0.224;
				} else if (channels == 3) {
					out[(0 * height + y) * width + x] = ((r / 255.0) - 0.5) / 0.5;
					out[(1 * height + y) * width + x] = ((g / 255.0) - 0.5) / 0.5;
					out[(2 * height + y) * width + x] = ((b / 255.0) - 0.5) / 0.5;
				} else {
					out[(0 * height + y) * width + x] = ((r / 255.0) - 0.5) / 0.5;
				}
			}
		}

		return out;
	}

	img.Image _pngRgbaBlackPreprocess(img.Image source) {
		final dst = img.Image(width: source.width, height: source.height, numChannels: 3);
		for (var y = 0; y < source.height; y++) {
			for (var x = 0; x < source.width; x++) {
				final p = source.getPixel(x, y);
				final a = p.a;
				if (a == 0) {
					dst.setPixelRgb(x, y, 255, 255, 255);
				} else {
					dst.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
				}
			}
		}
		return dst;
	}

	OrtValue _pickPrimaryOutput(Map<String, OrtValue> outputs) {
		if (_session.outputNames.isNotEmpty) {
			final key = _session.outputNames.first;
			final fromNamed = outputs[key];
			if (fromNamed != null) {
				return fromNamed;
			}
		}
		return outputs.values.first;
	}

	List<int> _decodeIndices({
		required List<int> shape,
		required List<double> data,
		required int charsetLen,
		List<int>? allowedClassIndices,
	}) {
		if (shape.isEmpty) {
			throw StateError('invalid output shape: empty');
		}

		final total = shape.fold<int>(1, (acc, dim) => acc * dim);
		if (data.length < total) {
			throw StateError('output data length ${data.length} is less than expected $total for shape $shape');
		}

		final classAxisCandidates = <int>[];
		for (var i = 0; i < shape.length; i++) {
			if (shape[i] == charsetLen) {
				classAxisCandidates.add(i);
			}
		}

		int classAxis;
		if (classAxisCandidates.isNotEmpty) {
			classAxis = classAxisCandidates.last;
		} else {
			classAxis = 0;
			for (var i = 1; i < shape.length; i++) {
				if (shape[i] > shape[classAxis]) {
					classAxis = i;
				}
			}
		}

		final nonClassAxes = <int>[];
		for (var i = 0; i < shape.length; i++) {
			if (i != classAxis) {
				nonClassAxes.add(i);
			}
		}

		int timeAxis = nonClassAxes.first;
		for (final axis in nonClassAxes) {
			if (shape[axis] > shape[timeAxis]) {
				timeAxis = axis;
			}
		}

		final classes = shape[classAxis];
		final seq = shape[timeAxis];
		if (classes <= 0 || seq <= 0) {
			throw StateError('invalid classes/seq inferred from shape $shape');
		}

		final strides = List<int>.filled(shape.length, 1);
		for (var i = shape.length - 2; i >= 0; i--) {
			strides[i] = strides[i + 1] * shape[i + 1];
		}

		final indices = List<int>.filled(shape.length, 0);
		final classCandidates = (allowedClassIndices == null || allowedClassIndices.isEmpty)
				? null
				: allowedClassIndices.where((c) => c >= 0 && c < classes).toList(growable: false);
		final allClasses = List<int>.generate(classes, (i) => i, growable: false);
		final decodeClasses = (classCandidates == null || classCandidates.isEmpty) ? allClasses : classCandidates;
		final result = <int>[];
		for (var t = 0; t < seq; t++) {
			indices[timeAxis] = t;
			var bestIdx = 0;
			var bestVal = -double.infinity;
			for (final c in decodeClasses) {
				indices[classAxis] = c;
				var offset = 0;
				for (var d = 0; d < shape.length; d++) {
					offset += indices[d] * strides[d];
				}
				final v = data[offset];
				if (v > bestVal) {
					bestVal = v;
					bestIdx = c;
				}
			}
			result.add(bestIdx);
		}

		return result;
	}
}
