# 天璇 (Tianxuan) API 文档

> 1Panel v2.x 第三方管理器 — API 接口参考
> 版本: 0.2.0 | 更新时间: 2026-06-22

---

## 目录

1. [认证机制](#1-认证机制)
2. [基础信息](#2-基础信息)
3. [仪表盘 API](#3-仪表盘-api)
4. [网站管理 API](#4-网站管理-api)
5. [文件管理 API](#5-文件管理-api)
6. [备份管理 API](#6-备份管理-api)
7. [其他 API](#7-其他-api)
8. [附录](#8-附录)

---

## 1. 认证机制

**认证方式**: API Key + md5 Token

**请求头**:

| Header | 值 | 必填 |
|--------|-----|------|
| `1Panel-Token` | `md5("1panel" + API-Key + UnixTimestamp)` | 是 |
| `1Panel-Timestamp` | Unix 秒级时间戳 | 是 |
| `Content-Type` | `application/json` | POST 请求是 |

**Token 生成示例** (Dart):

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String buildToken(String apiKey, int timestamp) {
  final raw = '1panel$apiKey$timestamp';
  return md5.convert(utf8.encode(raw)).toString();
}
```

**注意**:
- 时间戳误差超 5 分钟会返回 `401 API 接口时间戳错误`
- 无认证或过期会话返回 `401`
- 所有 API 响应格式统一为 `{"code": 200/400/500, "message": "...", "data": ...}`

---

## 2. 基础信息

### 2.1 API 路径

```
Base URL: http://<host>:<port>/api/v2/
所有接口均在 /api/v2/ 下
```

### 2.2 统一响应格式

```json
// 成功
{"code": 200, "message": "", "data": {...} }

// 参数错误
{"code": 400, "message": "参数错误: Key: 'Field' Error:...", "data": null}

// 服务错误
{"code": 500, "message": "服务错误: ...", "data": null}

// 鉴权失败
{"code": 401, "message": "API 接口时间戳错误", "data": null}
```

### 2.3 通用枚举

**网站类型** (`type`):

| 值 | 说明 |
|-----|------|
| `static` | 静态网站 |
| `proxy` | 反向代理 |
| `redirect` | 重定向 |
| `deployment` | 部署 (需 appType) |
| `runtime` | 运行环境 |
| `subsite` | 子站点 |

**网站状态** (`status`):

| 值 | 说明 |
|-----|------|
| `Running` | 运行中 |
| `Stopped` | 已停止 |
| `Error` | 异常 |

**操作动作** (`operate`):

| 值 | 说明 |
|-----|------|
| `start` | 启动 |
| `stop` | 停止 |
| `restart` | 重启 |

**日志类型** (`logType`):

| 值 | 说明 |
|-----|------|
| `access` | 访问日志 |
| `error` | 错误日志 |

**备份类型** (`type`，用于 backups):

| 值 | 说明 |
|-----|------|
| `website` | 网站备份 |
| `database` | 数据库备份 |
| `directory` | 目录备份 |

**排序方向** (`order`):

| 值 | 说明 |
|-----|------|
| `ascending` | 升序 (注意: 完整单词) |
| `descending` | 降序 |

---

## 3. 仪表盘 API

### 3.1 服务器基础信息 + 资源使用率

```
GET /dashboard/base/0/0
```

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "cpuCores": 4,
    "cpuPercent": [{ "time": "..." , "percent": 2.5 }],
    "memory": { "total": 8331833344, "used": 3246321664, "percent": 39.0 },
    "disk": { "total": 42160017408, "used": 24997986304, "percent": 59.3 },
    "uptime": 9623850,
    "hostname": "***",
    "platform": "Debian GNU/Linux 13",
    "platformVersion": "",
    "kernelVersion": "6.12.38+deb13",
    "kernelArch": "x86_64",
    "os": "linux"
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `cpuCores` | int | CPU 核心数 |
| `cpuPercent` | array | CPU 使用率时序数据 |
| `memory.total` | int | 总内存 (bytes) |
| `memory.used` | int | 已用内存 (bytes) |
| `memory.percent` | double | 内存使用率 (0-100) |
| `disk.total` | int | 总磁盘 (bytes) |
| `disk.used` | int | 已用磁盘 (bytes) |
| `disk.percent` | double | 磁盘使用率 (0-100) |
| `uptime` | int | 运行时间 (秒) |
| `hostname` | string | 主机名 |
| `platform` | string | 发行版名称 |

### 3.2 实时资源使用率

```
GET /dashboard/current/0/0
```

返回当前瞬时 CPU/内存/磁盘/网络 IO 数据。

---

## 4. 网站管理 API

### 4.1 获取网站列表 (简要)

```
GET /websites/list
```

**响应**: Website 对象数组 (简要字段: id, primaryDomain, type, alias, status, sitePath 等)。

### 4.2 分页搜索网站

```
POST /websites/search
```

**请求体**:

```json
{
  "page": 1,
  "pageSize": 20,
  "orderBy": "createdAt",
  "order": "ascending",
  "search": ""   // 可选搜索关键词
}
```

**响应**:

```json
{
  "code": 200,
  "data": {
    "total": 8,
    "items": [
      {
        "id": 4,
        "primaryDomain": "***.vip",
        "type": "proxy",
        "alias": "***.vip",
        "status": "Running",
        "sitePath": "/opt/1panel/www/sites/***.vip",
        "sslStatus": "danger",
        "sslExpireDate": "0001-01-01T00:00:00Z",
        "appName": "",
        "runtimeName": "",
        "favorite": false,
        "IPV6": false
      }
    ]
  }
}
```

### 4.3 获取网站详情

```
GET /websites/:id
```

**路径参数**: `id` — 网站 ID (int)

**响应**: Website 完整对象 (含 domains、webSiteSSL 嵌套对象)。

### 4.4 创建网站

```
POST /websites
```

**请求体**:

```json
{
  "primaryDomain": "example.com",
  "type": "static",
  "alias": "example.com",
  "websiteGroupID": 1,
  "appType": "installed",
  "remark": "",
  "proxy": "",
  "redirectURL": "",
  "port": null
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `primaryDomain` | string | 是 | 主域名 |
| `type` | string | 是 | 网站类型 (static/proxy/redirect/deployment) |
| `alias` | string | 是 | 别名，通常与域名相同 |
| `websiteGroupID` | int | 是 | 分组 ID (默认 1) |
| `appType` | string | 是 | `"installed"` 或 `"new"` (deployment 类型用) |
| `remark` | string | 否 | 备注 |
| `proxy` | string | type=proxy 时 | 代理地址，如 `http://127.0.0.1:8080` |
| `redirectURL` | string | type=redirect 时 | 重定向目标 URL |
| `port` | int | 否 | 自定义端口 |
| `appInstallID` | int | deployment 时 | 应用安装 ID |
| `runtimeID` | int | runtime 时 | 运行时 ID |

**响应**: HTTP 200 空响应 (成功) 或 400 (参数错误)。

### 4.5 删除网站

```
POST /websites/del
```

**请求体**:

```json
{"id": 4}
```

### 4.6 操作网站 (启停)

```
POST /websites/operate
```

**请求体**:

```json
{
  "id": 4,
  "operate": "start"   // start | stop | restart
}
```

### 4.7 更新网站

```
POST /websites/update
```

**请求体**:

```json
{
  "id": 4,
  "primaryDomain": "example.com",
  "type": "proxy",
  "alias": "example.com",
  "websiteGroupID": 1
}
```

可更新字段: `primaryDomain`, `type`, `alias`, `remark`, `proxy`, `redirectURL`。

### 4.8 预检查域名

```
POST /websites/check
```

**请求体**:

```json
{
  "primaryDomain": "example.com",
  "type": "static"
}
```

**响应**: `{"code": 200, "message": "", "data": null}` — 表示可创建。

### 4.9 获取 Nginx 配置

```
POST /websites/config
```

**请求体**:

```json
{
  "websiteID": 4,
  "scope": "all"    // all | nginx | www | proxy | rewrite | redirect
}
```

**响应**: `{"content": "server { ... }"}` 或 `null` (默认配置)。

### 4.10 更新 Nginx 配置

```
POST /websites/nginx/update
```

**请求体**:

```json
{
  "id": 4,
  "content": "server { listen 80; ... }",
  "scope": "nginx"
}
```

### 4.11 获取 HTTPS 配置

```
GET /websites/:id/https
```

**响应**:

```json
{
  "enable": false,
  "httpConfig": "",
  "SSL": { "id": 0, "primaryDomain": "", ... },
  "SSLProtocol": null,
  "hsts": false,
  "http3": false,
  "httpsPort": "443"
}
```

### 4.12 更新 HTTPS 配置

```
POST /websites/:id/https
```

**请求体**: SSL 配置字段。

### 4.13 获取网站日志

```
POST /websites/log
```

**请求体**:

```json
{
  "id": 4,
  "logType": "access",  // access | error
  "operate": "read"
}
```

**响应**:

```json
{
  "enable": true,
  "content": "192.168.1.1 - - [22/Jun/2026:10:00:00 +0800] ...",
  "end": false,
  "path": "/opt/1panel/www/sites/.../log/access.log"
}
```

### 4.14 获取网站目录

```
POST /websites/dir
```

**请求体**:

```json
{"id": 4}
```

**响应**:

```json
{
  "dirs": ["/"],
  "user": "0",
  "userGroup": "0"
}
```

### 4.15 获取网站选项 (域名列表)

```
POST /websites/options
```

**请求体**: `{}`

**响应**: 网站名称/域名列表。

---

## 5. 文件管理 API

基础路径 `/api/v2/files`。

### 5.1 搜索文件/文件夹

```
POST /files/search
```

**请求体**:

```json
{
  "path": "/opt/1panel/www/sites/",
  "search": "",
  "page": 1,
  "pageSize": 50,
  "expand": true,
  "sortBy": "name",
  "sortOrder": "asc"
}
```

**关键**: `expand: true` 才返回 items, 否则 items 为 null。

### 5.2 创建文件夹

```
POST /files
```

```json
{
  "path": "/opt/1panel/www/sites/new-site",
  "mode": 493   // = 0o755, 必须传 int, 不能传 string
}
```

### 5.3 读取文件内容

```
POST /files/content
```

```json
{
  "path": "/opt/1panel/www/sites/.../index.html"
}
```

**响应**: `{"content": "...文件内容..."}`

### 5.4 保存文件内容

```
POST /files/save
```

```json
{
  "path": "/opt/1panel/www/sites/.../index.html",
  "content": "<html>..."
}
```

### 5.5 重命名

```
POST /files/rename
```

```json
{
  "oldName": "/path/to/old.txt",
  "newName": "/path/to/new.txt"
}
```

### 5.6 删除文件

```
POST /files/del
```

```json
{"path": "/path/to/file.txt"}

// 批量:
POST /files/batch/del
{"paths": ["/path/1", "/path/2"]}
```

### 5.7 移动文件

```
POST /files/move
```

```json
{
  "oldPaths": ["/path/from.txt"],
  "newPaths": ["/path/to.txt"],
  "type": "move"   // 必须加 type: "move"
}
```

### 5.8 压缩

```
POST /files/compress
```

```json
{
  "paths": ["/path/to/dir"],
  "destination": "/path/to/archive.zip",
  "type": "zip"    // 必须加 type: "zip"
}
```

### 5.9 解压

```
POST /files/decompress
```

```json
{
  "path": "/path/to/archive.zip",
  "destination": "/path/to/extract",
  "type": "zip"    // 必须加 type: "zip"
}
```

### 5.10 修改权限

```
POST /files/mode
```

```json
{
  "path": "/path/to/file",
  "mode": 493,      // int, 十进制
  "user": "1000",
  "userGroup": "1000"
}
```

### 5.11 检查文件是否存在

```
POST /files/check
```

```json
{"path": "/path/to/file"}
```

### 5.12 获取用户/用户组

```
POST /files/user/group
```

**响应**:

```json
{
  "users": [{ "username": "www-data", "group": "www-data" }],
  "groups": ["www-data", "root"]
}
```

### 5.13 获取挂载点

```
POST /files/mount
```

```json
{"path": "/"}
```

### 5.14 获取文件大小

```
POST /files/size
```

```json
{"path": "/path/to/file"}
```

### 5.15 下载文件

```
GET /files/download?path=/path/to/file
```

返回二进制流 (dio 使用 `responseType: ResponseType.bytes`)。

### 5.16 上传文件

```
POST /files/upload
```

Multipart form-data:
- `path` — 目标目录
- `file` — 文件内容

支持 bytes 上传:

```
POST /files/upload
Content-Type: multipart/form-data

path: /target/dir
file: @filename
```

---

## 6. 备份管理 API

### 6.1 备份账户列表

```
POST /backups/search
```

```json
{
  "page": 1,
  "pageSize": 50,
  "orderBy": "createdAt",
  "order": "ascending"
}
```

**响应**:

```json
{
  "total": 1,
  "items": [
    {
      "id": 1,
      "name": "localhost",
      "type": "LOCAL",
      "backupPath": "/opt/1panel/backup",
      "createdAt": "2026-03-01T01:43:52+08:00"
    }
  ]
}
```

### 6.2 创建备份

```
POST /backups/backup
```

```json
{
  "type": "website",
  "detail": { "id": 4, "name": "***.vip" },
  "backupAccountID": 1
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | 备份类型: website / database / directory |
| `detail.id` | int | 资源 ID |
| `detail.name` | string | 资源名称 |
| `backupAccountID` | int | 备份账户 ID (从 /backups/search 获取) |

### 6.3 搜索备份记录

```
POST /backups/record/search
```

```json
{
  "page": 1,
  "pageSize": 10,
  "type": "website",
  "orderBy": "createdAt",
  "order": "ascending"
}
```

**响应**:

```json
{
  "total": 0,
  "items": [
    {
      "id": 1,
      "fileName": "website_blog_20260622.tar.gz",
      "fileSize": "1048576",
      "createdAt": "2026-06-22T10:00:00+08:00",
      "backupAccountName": "localhost",
      "backupType": "LOCAL",
      "source": "website"
    }
  ]
}
```

### 6.4 按计划任务搜索备份

```
POST /backups/record/search/bycronjob
```

```json
{
  "page": 1,
  "pageSize": 10,
  "type": "website",
  "orderBy": "createdAt",
  "order": "ascending",
  "cronjobID": 1
}
```

### 6.5 删除备份记录

```
POST /backups/record/del
```

```json
{"id": 1}
```

### 6.6 下载备份记录

```
POST /backups/record/download
```

```json
{"id": 1}
```

### 6.7 获取备份大小

```
POST /backups/record/size
```

```json
{
  "type": "website",
  "detail": { "id": 4 },
  "page": 1,
  "pageSize": 10,
  "orderBy": "createdAt",
  "order": "ascending"
}
```

### 6.8 更新备份记录描述

```
POST /backups/record/description/update
```

```json
{
  "id": 1,
  "description": "每周自动备份"
}
```

---

## 7. 其他 API

### 7.1 获取备份本地目录

```
GET /backups/local
```

### 7.2 获取备份选项

```
GET /backups/options
```

### 7.3 获取本地备份基础目录

```
GET /settings/basedir
```

---

## 8. 附录

### 8.1 Website 完整模型

```dart
class Website {
  int id;
  String primaryDomain;    // 主域名
  String type;             // static | proxy | redirect | deployment
  String alias;            // 别名
  String status;           // Running | Stopped | Error
  String remark;           // 备注
  String? proxy;           // 代理地址 (proxy 类型)
  String? redirectURL;     // 重定向 URL (redirect 类型)
  String? sitePath;        // 网站路径
  String? errorLogPath;    // 错误日志路径
  String? accessLogPath;   // 访问日志路径
  int port;                // 端口
  bool errorLog;           // 错误日志启用
  bool accessLog;          // 访问日志启用
  bool favorite;           // 收藏
  bool iPV6;               // IPv6 启用
  List<Domain> domains;    // 绑定域名列表
  WebSiteSSL? ssl;         // SSL 证书信息
  String? sslStatus;       // SSL 状态
  String? sslExpireDate;   // SSL 过期时间
  String createdAt;        // 创建时间
}
```

### 8.2 BackupRecord 模型

```dart
class BackupRecord {
  int id;
  String fileName;          // 文件名
  String fileSize;          // 文件大小 (bytes)
  String createdAt;         // 创建时间
  String? backupAccountName; // 备份账户名
  String? backupType;       // 备份类型 (LOCAL, S3, OSS...)
  String? source;           // 来源
}
```

### 8.3 WebsiteCreateRequest

```json
{
  "primaryDomain": "string (required)",
  "type": "string (required, oneof: static/proxy/redirect/deployment)",
  "alias": "string (required)",
  "websiteGroupID": "int (required, default: 1)",
  "appType": "string (required, oneof: installed/new)",
  "remark": "string (optional)",
  "proxy": "string (optional, required when type=proxy)",
  "redirectURL": "string (optional, required when type=redirect)",
  "port": "int (optional)",
  "appInstallID": "int (optional, default: 0)",
  "runtimeID": "int (optional, default: 0)"
}
```

### 8.4 首页 API 对照

| 页面 | 数据来源 | 接口 |
|------|---------|------|
| 仪表盘 | ServerStatus | `GET /dashboard/base/0/0` |
| 网站列表 | List\<Website\> | `GET /websites/list` |
| 网站详情 | Website | `GET /websites/:id` |
| 网站创建 | - | `POST /websites` |
| 网站启停 | - | `POST /websites/operate` |
| 网站删除 | - | `POST /websites/del` |
| Nginx 配置 | String | `POST /websites/config` |
| HTTPS 配置 | Map | `GET /websites/:id/https` |
| 网站日志 | Map | `POST /websites/log` |
| 网站目录 | Map | `POST /websites/dir` |
| 文件列表 | List\<FileItem\> | `POST /files/search` |
| 文件内容 | String | `POST /files/content` |
| 备份列表 | List\<BackupRecord\> | `POST /backups/record/search` |
| 创建备份 | - | `POST /backups/backup` |
| 删除备份 | - | `POST /backups/record/del` |

### 8.5 更新日志

| 版本 | 日期 | 变更 |
|------|------|------|
| 0.1.0 | 2026-06-21 | 初始版本: 仪表盘、网站列表、文件管理器 |
| 0.2.0 | 2026-06-22 | 网站创建、详情页 (SSL/日志/备份)、API 文档 |
