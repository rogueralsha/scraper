class M3u8File {
  List<String> lines;
  List<String> files;

  M3u8File.parse(String input) {
    for (String line in input.split("\r\n")) {
      if (line.startsWith("#")) continue;

      files.add(input);
    }
  }
}
