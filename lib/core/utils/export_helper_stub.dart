// Copyright (c) 2026
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename, String mimeType) {
  // Stub implementation for non-web platforms. Should never be called without guarding kIsWeb.
  throw UnsupportedError('downloadImage is not supported on this platform');
}
