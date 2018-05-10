class ImgurSource {
//  albumRegexp: new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/(a|gallery)\\/([^\\/]+)", 'i'),
  static final RegExp postRegexp = new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\$", caseSensitive: false);
//  videoRegexp: new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\.gifv$", 'i'),
//  directRegexp: new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\\.[a-z]{3,4}$", 'i'),

}