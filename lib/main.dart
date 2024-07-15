import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Google Sing In Function
  GoogleSignIn? googleSignIn;
  googleSingIn() async {
    await googleSignIn?.signIn();
  }

  // Google Sing In Function
  // get vidoe from Gallery
  getVideo() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickVideo(source: ImageSource.gallery);
    if (xFile != null) {
      uploadVideo(File(xFile.path));
    }
  }
  // get vidoe from Gallery

  // upload video on YouTube
  uploadVideo(File myVideo) async {
    Map<String, String> authHeader =
        await googleSignIn!.currentUser!.authHeaders;

    IOClient ioClient = IOClient(HttpClient());
    AuthenticatedClient authenticatedClient =
        AuthenticatedClient(ioClient, authHeader);

    YouTubeApi youTubeApi = YouTubeApi(authenticatedClient);
    // video setting
    Video video = Video(
        snippet: VideoSnippet(title: "test1", description: "Mohamed Abdo"),
        status: VideoStatus(privacyStatus: "private"));
    // video setting

    final stream = myVideo.openRead();
    Media media = Media(stream, await myVideo.length());

    //upload Video
    await youTubeApi.videos
        .insert(video, ["snippet", "status"], uploadMedia: media);
    //upload Video
  }

  // upload video on YouTube
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    googleSignIn= GoogleSignIn(scopes: [
      YouTubeApi.youtubeUploadScope, // to can upload vidoes
      YouTubeApi.youtubeReadonlyScope // fetch Videos from me account
    ]);
    googleSingIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            getVideo();
          },
          child: Container(
            height: 50,
            width: 200,
            color: Colors.black,
            child: Center(
                child: Text(
              "Upload Video",
              style: TextStyle(color: Colors.white),
            )),
          ),
        ),
      ),
    );
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }
}
