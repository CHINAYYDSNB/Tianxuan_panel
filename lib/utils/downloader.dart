/// 跨平台文件下载
/// Web → Blob 下载
/// Native → 保存到应用文档目录
export 'src/downloader_stub.dart'
    if (dart.library.html) 'src/downloader_web.dart';
