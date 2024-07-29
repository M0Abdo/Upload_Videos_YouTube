// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:googleapis/youtube/v3.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';
// import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//    _pickVideo() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       final videoFile = File(pickedFile.path);
//       await uploadVideo(videoFile);
//     } else {
//       print('No video selected.');
//     }
//   }
//   googleLogIn() async {
//      final GoogleSignIn googleSignIn = GoogleSignIn(
//       scopes: [
//         YouTubeApi.youtubeReadonlyScope,
//         YouTubeApi.youtubeUploadScope,
//       ],
//     );
//      await googleSignIn.signIn();
//   }

// uploadVideo(File videoFile) async {

//     Map<String,String> authHeaders = await GoogleSignIn().currentUser!.authHeaders;
//     IOClient httpClient = IOClient(HttpClient());
//     AuthenticatedClient authenticatedClient = AuthenticatedClient(httpClient, authHeaders);

//     YouTubeApi youTubeApi = YouTubeApi(authenticatedClient);
//     Stream<List<int>> stream = videoFile.openRead();
//     Media media = Media(stream, await videoFile.length());
//     // video sitting
//     final video = Video(
//       snippet: VideoSnippet(
//         title: 'test1',
//         description: 'My video description',

//       ),
//       status: VideoStatus(
//         privacyStatus: 'private', //video staus ( private , public )
//       ),
//     );
//     // upload Videos
//      await youTubeApi.videos.insert(
//       video,
//       ['snippet', 'status'],
//       uploadMedia: media,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         child: Center(
//           child: GestureDetector(
//               onTap: () {
//                 _pickVideo();
//               },
//               child: Container(height: 50, width: 100, color: Colors.black)),
//         ),
//       ),
//     );
//   }
// }

// class AuthenticatedClient extends http.BaseClient {
//   final http.Client _inner;
//   final Map<String, String> _headers;

//   AuthenticatedClient(this._inner, this._headers);

//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     return _inner.send(request..headers.addAll(_headers));
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Private Videos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  String? _accessToken;
  List _videos = [];
  String image = "";

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
      GoogleSignInAuthentication auth =
          await _googleSignIn.currentUser!.authentication;
      setState(() {
        _accessToken = auth.accessToken;
      });
      await fetchPrivateVideos();
    } catch (error) {
      print(error);
    }
  }

  Future<void> fetchPrivateVideos() async {
    if (_accessToken == null) return;

    // Get the user's channel ID
    final channelResponse = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&mine=true'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (channelResponse.statusCode != 200) {
      print('Failed to fetch channel details');
      return;
    }

    var channelData = json.decode(channelResponse.body);
    print('-----------------------------------------------');
    print(channelData);
    String uploadPlaylistId = channelData['items'][0]['contentDetails']
        ['relatedPlaylists']['uploads'];

    // Fetch videos from the uploads playlist
    final response = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$uploadPlaylistId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
    
      setState(() {
        _videos = data['items'];
      });
    } else {
      print('Failed to fetch videos');
    }
  }

  @override
  void initState() {
    _handleSignIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            onTap: () {
              fetchPrivateVideos();
            },
            child: Container(child: Text('YouTube Private Videos'))),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: ListView.builder(
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            var video = _videos[index];
            return ListTile(
              leading: Container(
                  height: 120,
                  width: 50,
                  child: Image.network(
                      video['snippet']['thumbnails']['default']['url'])),
              title: Text(video['snippet']['title']),
              subtitle: Text(video['snippet']['description']),
            );
          },
        ),
      ),
    );
  }
}
