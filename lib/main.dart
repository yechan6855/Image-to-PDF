import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image to PDF Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageToPdfConverter(),
    );
  }
}

class ImageToPdfConverter extends StatefulWidget {
  @override
  _ImageToPdfConverterState createState() => _ImageToPdfConverterState();
}

class _ImageToPdfConverterState extends State<ImageToPdfConverter> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3144814155177659/1234567890', // 실제 배너 광고 ID로 교체해야 합니다
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> convertToPDF() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final pdfPath = '${tempDir.path}/output.pdf';

      // 이미지를 PDF로 변환
      final pdf = pw.Document();

      final image = img.decodeImage(await _image!.readAsBytes());
      final pngData = img.encodePng(image!);
      final pdfImage = pw.MemoryImage(
        Uint8List.fromList(pngData),
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage),
            );
          },
        ),
      );

      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isLoading = false;
      });

      // PDF 파일 열기
      await OpenFile.open(pdfPath);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 변환에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image to PDF Converter'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _image == null
                      ? Text('이미지가 선택되지 않았습니다.')
                      : Image.file(_image!, height: 300),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: getImage,
                    child: Text('이미지 선택'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _image == null ? null : convertToPDF,
                    child: Text('PDF로 변환'),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          if (_isBannerAdReady)
            Container(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}