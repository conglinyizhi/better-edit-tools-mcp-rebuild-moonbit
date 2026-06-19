#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stdio.h>
#include <string.h>

#ifdef _WIN32
#include <direct.h>
#include <fcntl.h>
#include <io.h>
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT
int be_atomic_rename(moonbit_bytes_t from, moonbit_bytes_t to) {
  int rc = rename((const char *)from, (const char *)to);
  if (rc != 0) {
    return errno;
  }
  return 0;
}

MOONBIT_FFI_EXPORT
int be_atomic_fsync_file(moonbit_bytes_t path) {
#ifdef _WIN32
  int fd = _open((const char *)path, _O_RDONLY);
  if (fd < 0) {
    return errno;
  }
  int rc = _commit(fd);
  int saved_errno = errno;
  _close(fd);
  if (rc != 0) {
    return saved_errno;
  }
#else
  int fd = open((const char *)path, O_RDONLY);
  if (fd < 0) {
    return errno;
  }
  int rc = fsync(fd);
  int saved_errno = errno;
  close(fd);
  if (rc != 0) {
    return saved_errno;
  }
#endif
  return 0;
}

MOONBIT_FFI_EXPORT
int be_atomic_fsync_dir(moonbit_bytes_t path) {
#ifdef _WIN32
  int fd = _open((const char *)path, _O_RDONLY);
  if (fd < 0) {
    return errno;
  }
  int rc = _commit(fd);
  int saved_errno = errno;
  _close(fd);
  if (rc != 0) {
    return saved_errno;
  }
#else
  int fd = open((const char *)path, O_RDONLY | O_DIRECTORY);
  if (fd < 0) {
    return errno;
  }
  int rc = fsync(fd);
  int saved_errno = errno;
  close(fd);
  if (rc != 0) {
    return saved_errno;
  }
#endif
  return 0;
}

#ifdef __cplusplus
}
#endif
