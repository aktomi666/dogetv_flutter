import 'dart:convert';

import 'package:dogetv_flutter/models/category.dart';
import 'package:dogetv_flutter/models/channel.dart';
import 'package:dogetv_flutter/models/episode.dart';
import 'package:dogetv_flutter/models/video.dart';
import 'package:dogetv_flutter/models/home.dart';
import 'package:dogetv_flutter/models/video_detail.dart';
import 'package:http/http.dart' as http;

class APIs {
  static const String BASE_URL = "http://111.231.243.232/";

  static Future<Home> getHome() async {
    Future getTopics = http.get("$BASE_URL/topics");
    Future getSections = http.get("$BASE_URL/videos");

    List<http.Response> responseDatas =
        await Future.wait([getTopics, getSections]);

    Map topics = json.decode(responseDatas.first.body);
    Map sections = json.decode(responseDatas.last.body);

    Home home = Home();
    home.sections = (sections["data"] as List)
        .map((v) => VideoSection.fromJson(v))
        .toList();
    home.topics =
        (topics["data"] as List).map((v) => Topic.fromJson(v)).toList();
    return home;
  }

  static Future<CategoryVideo> getVideos(Category category,
      {String queryString = "-Shot", int pageIndex = 1}) async {
    String key = category.toString().replaceAll("Category.", "");
    var response =
        await http.get("$BASE_URL/videos/$key?p=$pageIndex&query=$queryString");
    Map map = json.decode(response.body);

    if (map["data"] == null) {
      return Future.error(map["msg"]);
    }

    CategoryVideo videos = CategoryVideo.fromJson(map["data"]);
    return videos;
  }

  static Future<List<Topic>> getTopics() async {
    var response = await http.get("$BASE_URL/topics");
    Map map = json.decode(response.body);
    List<Topic> topics =
        (map["data"] as List).map((v) => Topic.fromJson(v)).toList();
    return topics;
  }

  static Future<List<Video>> search(String keywords,
      {int pageIndex = 1}) async {
    var response = await http.get("$BASE_URL/search?wd=$keywords&p=$pageIndex");
    Map map = json.decode(response.body);
    List<Video> results =
        (map["data"] as List).map((v) => Video.fromJson(v)).toList();
    return results;
  }

  static Future<List<Video>> getTopicDetail(String topicId) async {
    if (topicId == null) {
      return null;
    }
    var response = await http.get("$BASE_URL/topic/$topicId");
    Map map = json.decode(response.body);
    List<Video> topicVideos =
        (map["data"]["items"] as List).map((v) => Video.fromJson(v)).toList();
    return topicVideos;
  }

  static Future<List<TV>> getTVChannels({bool isIPTV}) async {
    var response = await http.get("$BASE_URL/tv${isIPTV ? "?f=iptv" : ""}");
    Map map = json.decode(response.body);

    List<TV> groups = (map["data"] as List).map((v) => TV.fromJson(v)).toList();

    groups.forEach(
        (v) => v.channels.sort((r1, r2) => r1.name.compareTo(r2.name)));

    return groups;
  }

  static Future<VideoDetail> getVideo(String videoId) async {
    Future getVideo = http.get("$BASE_URL/video/$videoId");
    Future getEpisodes = http.get("$BASE_URL/video/$videoId/episodes");

    List<http.Response> responseDatas =
        await Future.wait([getVideo, getEpisodes]);
    Map video = json.decode(responseDatas[0].body);
    Map episodesMap = json.decode(responseDatas[1].body);

    if (video["code"] != 200 || episodesMap["code"] != 200) {
      return null;
    }

    VideoDetail videoDetail = VideoDetail();
    videoDetail.video = VideoInfo.fromJson(video["data"]);
    videoDetail.episodes =
        (episodesMap["data"] as List).map((v) => Episode.fromJson(v)).toList();
    return videoDetail;
  }

  static Future<String> getStreamURL(String source) async {
    Map params = {"url": source};
    var response = await http.post("$BASE_URL/video/resolve", body: params);
    Map stream = json.decode(response.body);
    return stream["data"];
  }

  static Future<List<Episode>> getEpisodes(
      String videoId, String source) async {
    var response =
        await http.get("$BASE_URL/video/$videoId/episodes?source=$source");
    var episodesMap = json.decode(response.body);

    List<Episode> episodes = [];
    if (episodesMap["code"] != 200) {
      return episodes;
    }

    for (var episode in episodesMap["data"]) {
      episodes.add(Episode.fromJson(episode));
    }
    return episodes;
  }
}
