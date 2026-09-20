import 'package:flutter_test/flutter_test.dart';
import 'package:origine/core/utils/media_url.dart';

void main() {
  const mov = 'https://res.cloudinary.com/demo/video/upload/v1789/story_media/abc.mov';
  const mp4 = 'https://res.cloudinary.com/demo/video/upload/v1789/story_media/abc.mp4';

  test('un .mov est converti en MP4 H.264 à la volée', () {
    expect(videoPlaybackUrl(mov),
        'https://res.cloudinary.com/demo/video/upload/f_mp4,vc_h264,ac_aac/v1789/story_media/abc.mp4');
  });

  test('un .mp4 est lu tel quel', () {
    expect(videoPlaybackUrl(mp4), mp4);
  });

  test('aperçu = première image en jpg', () {
    expect(videoPosterUrl(mov),
        'https://res.cloudinary.com/demo/video/upload/so_0,w_480,h_320,c_fill/v1789/story_media/abc.jpg');
  });

  test('URL non-Cloudinary (dev local) inchangée, sans aperçu', () {
    const local = 'http://localhost:8001/uploads/story_media/x.mov';
    expect(videoPlaybackUrl(local), local);
    expect(videoPosterUrl(local), isNull);
  });
}
