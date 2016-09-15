use std::path::{Path, PathBuf};
use std::fs::{self, Metadata};
use std::ffi::OsStr;
use std::{slice, str, ptr, mem};
use std::ops::Deref;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PathObj {
    _p: usize,
    _l: usize,
}

impl<'a> From<&'a Path> for PathObj {
    fn from(p: &'a Path) -> PathObj {
        unsafe { mem::transmute(p) }
    }
}

impl<'a> From<Option<&'a Path>> for PathObj {
    fn from(p: Option<&'a Path>) -> PathObj {
        unsafe { mem::transmute(p) }
    }
}

impl Deref for PathObj {
    type Target = Path;
    fn deref(&self) -> &Path {
        unsafe { mem::transmute(*self) }
    }
}

impl AsRef<Path> for PathObj {
    fn as_ref(&self) -> &Path {
        &**self
    }
}

impl AsRef<OsStr> for PathObj {
    fn as_ref(&self) -> &OsStr {
        (&**self).as_ref()
    }
}

/// Create an empty path which can be appended onto
#[no_mangle]
pub unsafe extern "C"
fn path_temp_obj(path: *const u8, len: usize) -> PathObj {
    let raw = slice::from_raw_parts(path, len);
    let path = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return None.into(),
    };

    Path::new(path).into()
}

/// Create an empty path which can be appended onto
#[no_mangle]
pub unsafe extern "C"
fn path_empty() -> *mut PathBuf {
    Box::into_raw(Box::new(PathBuf::new()))
}

/// Clone a path
#[no_mangle]
pub unsafe extern "C"
fn path_clone(path: *mut PathBuf) -> *mut PathBuf {
    Box::into_raw(Box::new((*path).clone()))
}

/// Clone a path
#[no_mangle]
pub unsafe extern "C"
fn path_buf_from_obj(path: PathObj) -> *mut PathBuf {
    Box::into_raw(Box::new(PathBuf::from(&path)))
}

/// Create a basic path from a UTF-8 string
#[no_mangle]
pub unsafe extern "C"
fn path_create(path: *const u8, len: usize) -> *mut PathBuf {
    let raw = slice::from_raw_parts(path, len);
    let path = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    Box::into_raw(Box::new(PathBuf::from(path)))
}

/// Free a path
#[no_mangle]
pub unsafe extern "C"
fn path_free(path: *mut PathBuf) {
    Box::from_raw(path);
}

/// Append a string to a path
#[no_mangle]
pub unsafe extern "C"
fn path_push(path: *mut PathBuf, leaf: PathObj) {
    (*path).push(leaf);
}

#[no_mangle]
pub unsafe extern "C"
fn path_pop(path: *mut PathBuf) -> bool {
    (*path).pop()
}

#[no_mangle]
pub unsafe extern "C"
fn path_set_file_name(path: *mut PathBuf, leaf: *const u8, len: usize) -> bool {
    let raw = slice::from_raw_parts(leaf, len);
    let leaf = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return false,
    };

    (*path).set_file_name(leaf);
    true
}

#[no_mangle]
pub unsafe extern "C"
fn path_set_extension(path: *mut PathBuf, leaf: *const u8, len: usize) -> bool {
    let raw = slice::from_raw_parts(leaf, len);
    let leaf = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return false,
    };

    (*path).set_extension(leaf)
}

#[no_mangle]
pub unsafe extern "C"
fn path_buf_to_obj(buf: *const PathBuf) -> PathObj {
    (*buf).as_path().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_to_str(path: PathObj, len: *mut usize) -> *const u8 {
    let path = match (*path).to_str() {
        Some(p) => p,
        None => return ptr::null(),
    };
    
    *len = (*path).len();
    return (*path).as_ptr();
}

#[no_mangle]
pub unsafe extern "C"
fn path_is_absolute(path: PathObj) -> bool {
    path.is_absolute().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_is_relative(path: PathObj) -> bool {
    path.is_relative().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_has_root(path: PathObj) -> bool {
    path.has_root().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_starts_with(path: PathObj, start: PathObj) -> bool {
    path.starts_with(start)
}

#[no_mangle]
pub unsafe extern "C"
fn path_ends_with(path: PathObj, end: PathObj) -> bool {
    path.ends_with(end)
}

#[no_mangle]
pub unsafe extern "C"
fn path_exists(path: PathObj) -> bool {
    path.exists()
}

#[no_mangle]
pub unsafe extern "C"
fn path_is_file(path: PathObj) -> bool {
    path.is_file()
}

#[no_mangle]
pub unsafe extern "C"
fn path_is_dir(path: PathObj) -> bool {
    path.is_dir()
}

#[no_mangle]
pub unsafe extern "C"
fn path_parent(path: PathObj) -> PathObj {
    path.parent().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_strip_prefix(path: PathObj, prefix: PathObj) -> PathObj {
    path.strip_prefix(&prefix).ok().into()
}

#[no_mangle]
pub unsafe extern "C"
fn path_file_name(path: PathObj, len: *mut usize) -> *const u8 {
    let name = match path.file_name().and_then(OsStr::to_str) {
        Some(n) => n.as_bytes(),
        None => return ptr::null(),
    };

    *len = name.len();
    name.as_ptr()
}

#[no_mangle]
pub unsafe extern "C"
fn path_file_stem(path: PathObj, len: *mut usize) -> *const u8 {
    let stem = match path.file_name().and_then(OsStr::to_str) {
        Some(n) => n.as_bytes(),
        None => return ptr::null(),
    };

    *len = stem.len();
    stem.as_ptr()
}

#[no_mangle]
pub unsafe extern "C"
fn path_extension(path: PathObj, len: *mut usize) -> *const u8 {
    let ext = match path.file_name().and_then(OsStr::to_str) {
        Some(n) => n.as_bytes(),
        None => return ptr::null(),
    };

    *len = ext.len();
    ext.as_ptr()
}

#[no_mangle]
pub unsafe extern "C"
fn path_join(left: PathObj, right: PathObj) -> *mut PathBuf {
    Box::into_raw(Box::new(left.join(right)))
}

#[no_mangle]
pub unsafe extern "C"
fn path_with_file_name(path: PathObj, leaf: *const u8, len: usize) -> *mut PathBuf {
    let raw = slice::from_raw_parts(leaf, len);
    let leaf = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    Box::into_raw(Box::new(path.with_file_name(leaf)))
}

#[no_mangle]
pub unsafe extern "C"
fn path_with_extension(path: PathObj, leaf: *const u8, len: usize) -> *mut PathBuf {
    let raw = slice::from_raw_parts(leaf, len);
    let leaf = match str::from_utf8(raw) {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    Box::into_raw(Box::new(path.with_extension(leaf)))
}

#[no_mangle]
pub unsafe extern "C"
fn path_canonicalize(path: PathObj) -> *mut PathBuf {
    match path.canonicalize() {
        Ok(path) => Box::into_raw(Box::new(path)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub unsafe extern "C"
fn path_read_link(path: PathObj) -> *mut PathBuf {
    match path.read_link() {
        Ok(path) => Box::into_raw(Box::new(path)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub unsafe extern "C"
fn path_copy(from: PathObj, to: PathObj) -> u64 {
    fs::copy(from, to).unwrap_or(std::u64::MAX)
}

#[no_mangle]
pub unsafe extern "C"
fn path_create_dir(path: PathObj) -> bool {
    fs::create_dir(path).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_create_dir_all(path: PathObj) -> bool {
    fs::create_dir_all(path).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_remove_dir(path: PathObj) -> bool {
    fs::remove_dir(path).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_remove_dir_all(path: PathObj) -> bool {
    fs::remove_dir_all(path).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_remove_file(path: PathObj) -> bool {
    fs::remove_file(path).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_rename(from: PathObj, to: PathObj) -> bool {
    fs::rename(from, to).is_ok()
}

#[no_mangle]
pub unsafe extern "C"
fn path_hard_link(src: PathObj, dst: PathObj) -> bool {
    fs::hard_link(src, dst).is_ok()
}

#[cfg(windows)]
#[no_mangle]
pub unsafe extern "C"
fn path_symlink_file(src: PathObj, dst: PathObj) -> bool {
    use std::os::windows::fs::symlink_file;
    symlink_file(src, dst).is_ok()
}

#[cfg(windows)]
#[no_mangle]
pub unsafe extern "C"
fn path_symlink_dir(src: PathObj, dst: PathObj) -> bool {
    use std::os::windows::fs::symlink_dir;
    symlink_dir(src, dst).is_ok()
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C"
fn path_symlink_file(src: PathObj, dst: PathObj) -> bool {
    use std::os::unix::fs::symlink;
    symlink(src, dst).is_ok()
}

#[cfg(unix)]
#[no_mangle]
pub unsafe extern "C"
fn path_symlink_dir(src: PathObj, dst: PathObj) -> bool {
    use std::os::unix::fs::symlink;
    symlink(src, dst).is_ok()
}

//-----------------------
// Metadata functions

#[repr(C)]
pub enum MetaFileType {
        FT_File = 0,
        FT_Dir = 1,
        FT_SymLink = 2,
        FT_Other = 3,
}

#[no_mangle]
pub unsafe extern "C"
fn path_metadata(path: PathObj) -> *mut Metadata {
    match path.metadata() {
        Ok(meta) => Box::into_raw(Box::new(meta)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub unsafe extern "C"
fn path_symlink_metadata(path: PathObj) -> *mut Metadata {
    match path.symlink_metadata() {
        Ok(meta) => Box::into_raw(Box::new(meta)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_file_type(meta: *const Metadata) -> MetaFileType {
    let ty = (*meta).file_type();
    if ty.is_symlink() {
        MetaFileType::FT_SymLink
    } else if ty.is_file() {
        MetaFileType::FT_File
    } else if ty.is_dir() {
        MetaFileType::FT_Dir
    } else {
        MetaFileType::FT_Other
    } 
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_is_file(meta: *const Metadata) -> bool {
    (*meta).is_file()
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_is_dir(meta: *const Metadata) -> bool {
    (*meta).is_dir()
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_file_size(meta: *const Metadata) -> u64 {
    (*meta).len()
}

fn map_time<E>(time: Result<std::time::SystemTime, E>) -> i64 {
    use std::time::UNIX_EPOCH;
    time.map_err(|_|()).and_then(|time| {
        if time >= UNIX_EPOCH {
            Ok((try!(time.duration_since(UNIX_EPOCH).map_err(|_|())), 1))
        } else {
            Ok((try!(UNIX_EPOCH.duration_since(time).map_err(|_|())), -1))
        }
    }).map(|(dur, sign)| {
        dur.as_secs() as i64 * sign
    }).unwrap_or(std::i64::MIN)
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_modified(meta: *const Metadata) -> i64 {
    map_time((*meta).modified())
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_accessed(meta: *const Metadata) -> i64 {
    map_time((*meta).accessed())
}

#[no_mangle]
pub unsafe extern "C"
fn path_meta_created(meta: *const Metadata) -> i64 {
    map_time((*meta).accessed())
}

#[no_mangle]
pub unsafe extern "C"
fn path_free_metadata(meta: *mut Metadata) {
    Box::from_raw(meta);
}


