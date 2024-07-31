import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:upload_youtube/playVideo.dart';

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
  String accessToken = "";
  List videos = [];
  // Google Sing In Function
  GoogleSignIn? googleSignIn;
  googleSingIn() async {
    await googleSignIn?.signIn();
    GoogleSignInAuthentication auth =
        await googleSignIn!.currentUser!.authentication;
    setState(() {
      accessToken = auth.accessToken!;
    });
    fechVideos();
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
  // get me Videos in me Channel inYouTube
  fechVideos() async {
    if (accessToken.isEmpty) {
      print("empty");
      return;
    }

    final channelResponse = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&mine=true'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    var channelData = json.decode(channelResponse.body); // me channel Details

    String channelId = channelData["items"][0]["contentDetails"]
        ['relatedPlaylists']['uploads']; //id of me channel

    final videoResponse = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$channelId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (videoResponse.statusCode == 200) {
      var data = json.decode(videoResponse.body);
      print('--------------------------------');
      print(data);
      setState(() {
        videos = data['items'];
      });
    } else {
      print("Error");
    }
  }

  // get me Videos in me Channel inYouTube
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    googleSignIn = GoogleSignIn(scopes: [
      YouTubeApi.youtubeUploadScope, // to can upload vidoes
      YouTubeApi.youtubeReadonlyScope // fetch Videos from me account
    ]);
    googleSingIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () {
            getVideo();
          }),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: ListView.builder(
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PlayVideo(
                    videoId: videos[index]["snippet"]["resourceId"]["videoId"],
                  ),
                ));
              },
              leading: Container(
                  height: 120,
                  width: 120,
                  child: Image.network(videos[index]["snippet"]["thumbnails"]
                      ["default"]["url"])),
              title: Text(videos[index]["snippet"]["title"]),
              subtitle: Text(videos[index]["snippet"]["description"]),
            );
          },
          itemCount: videos.length,
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
