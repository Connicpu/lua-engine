--[[------------------------------------------------------------------------------------
Path API

type Path
type PathBuf : Path
type FileMeta

Path:to_str() -> string
Path:is_absolute() -> bool
Path:is_relative() -> bool
Path:has_root() -> bool
Path:starts_with(Path|string) -> bool
Path:ends_with(Path|string) -> bool
Path:exists() -> bool
Path:is_file() -> bool
Path:is_dir() -> bool
Path:parent() -> Path
Path:strip_prefix(Path|string) -> Path?
Path:file_name() -> string
Path:file_stem() -> string?
Path:extension() -> string?
Path:join(Path|string...) -> PathBuf
Path:with_file_name(string) -> PathBuf
Path:with_extension(string) -> PathBuf
Path:canonicalize() -> PathBuf?
Path:read_link() -> PathBuf?
Path:metadata() -> FileMeta?
Path:symlink_metadata() -> FileMeta?

PathBuf(Path|string)
PathBuf:clone() -> PathBuf
PathBuf:push(Path|string)
PathBuf:pop() -> bool
PathBuf:set_file_name(string)
PathBuf:set_extension(string)

FileMeta:file_type() -> string
FileMeta:is_file() -> bool
FileMeta:is_dir() -> bool
FileMeta:file_size() -> u64
FileMeta:modified() -> DateTime
FileMeta:accessed() -> i64
FileMeta:created() -> i64

NOTE: All path functions can be called directly on the module
and passed strings for convenience e.g.
local path = require("engine.utility.path")
local place = path.join("usr", "bin")

--]]------------------------------------------------------------------------------------

local ffi = require("ffi")

local ffi_istype = ffi.istype
local ffi_new = ffi.new
local ffi_string = ffi.string

ffi.cdef[[
    typedef struct PathObj {
        size_t _p;
        size_t _l;
    } PathObj;

    typedef struct RustPathBuf PBuf;
    struct PathBuf {
        PBuf *_buf;
        bool _has_po;
        PathObj _po;
    };

    typedef struct ReadDir ReadDir;

    typedef struct PMeta PMeta;
    typedef enum MetaFileType {
        FT_File = 0,
        FT_Dir = 1,
        FT_SymLink = 2,
        FT_Other = 3,
    } MetaFileType;
    struct FileMeta {
        PMeta *_meta;
    };

    void path_temp_obj(const char *str, size_t len, PathObj *output);
    PBuf *path_empty();
    PBuf *ppath_clone(const PBuf *buf);
    PBuf *path_buf_from_obj(const PathObj &path);
    PBuf *path_create(const char *path, size_t len);
    void path_free(PBuf *buf);

    bool path_push(PBuf *buf, PathObj leaf);
    bool path_pop(PBuf *buf);
    bool path_set_file_name(PBuf *buf, const char *name, size_t len);
    bool path_set_extension(PBuf *buf, const char *ext, size_t len);
    void path_buf_to_obj(PBuf *buf, PathObj *output);

    const char *path_to_str(const PathObj &path, size_t *len);

    bool path_is_absolute(const PathObj &path);
    bool path_is_relative(const PathObj &path);
    bool path_has_root(const PathObj &path);
    bool path_starts_with(const PathObj &path, const PathObj &start);
    bool path_ends_with(const PathObj &path, const PathObj &end);
    bool path_exists(const PathObj &path);
    bool path_is_file(const PathObj &path);
    bool path_is_dir(const PathObj &path);
    void path_parent(const PathObj &path, PathObj *output);
    void path_strip_prefix(const PathObj &path, const PathObj &prefix, PathObj *output);
    const char *path_file_name(const PathObj &path, size_t *len);
    const char *path_file_stem(const PathObj &path, size_t *len);    
    const char *path_extension(const PathObj &path, size_t *len);    

    PBuf *path_join(const PathObj &left, const PathObj &right);
    PBuf *path_with_file_name(const PathObj &path, const char *name, size_t len);
    PBuf *path_with_extension(const PathObj &path, const char *name, size_t len);
    PBuf *path_canonicalize(const PathObj &path);
    PBuf *path_read_link(const PathObj &path);

    uint64_t path_copy(const PathObj &from, const PathObj &to);
    bool path_create_dir(const PathObj &path);
    bool path_create_dir_all(const PathObj &path);
    bool path_remove_dir(const PathObj &path);
    bool path_remove_dir_all(const PathObj &path);
    bool path_remove_file(const PathObj &path);
    bool path_rename(const PathObj &from, const PathObj &to);
    bool path_hard_link(const PathObj &src, const PathObj &dst);
    bool path_symlink_file(const PathObj &src, const PathObj &dst);
    bool path_symlink_dir(const PathObj &src, const PathObj &dst);

    PMeta *path_metadata(const PathObj &path);
    PMeta *path_symlink_metadata(const PathObj &path);
    MetaFileType path_meta_file_type(const PMeta *meta);
    bool path_meta_is_file(const PMeta *meta);
    bool path_meta_is_dir(const PMeta *meta);
    uint64_t path_meta_file_size(const PMeta *meta);
    int64_t path_meta_modified(const PMeta *meta);
    int64_t path_meta_accessed(const PMeta *meta);
    int64_t path_meta_created(const PMeta *meta);
    void path_free_metadata(PMeta *meta);

    ReadDir *path_read_dir(const PathObj &path);
    PBuf *path_read_dir_next(ReadDir *rd);
    void path_free_read_dir(ReadDir *rd);
]]

local plib = ffi.load("path_helper")

local Path = {}
local Path_mt = { __index = Path }
local Path_ct

local PathBuf = {}
local PathBuf_mt = { __index = PathBuf }
local PathBuf_ct

local FileMeta = {}
local FileMeta_mt = { __index = FileMeta }
local FileMeta_ct

local function pathify(path)
    if ffi_istype(Path_ct, path) then
        return path
    elseif ffi_istype(PathBuf_ct, path) then
        if not path._has_po then
            plib.path_buf_to_obj(path._buf, path._po)
            path._has_po = true
        end
        return path._po
    elseif type(path) == 'string' then
        local obj = Path_ct()
        plib.path_temp_obj(path, #path, obj)
        if obj._p == 0 then
            error("String used as path which contains invalid UTF-8")
        end
        return Path_ct(obj)
    end
    error("Expected string or Path")
end

----------------------
-- Path functions

local temp_len = ffi.new("size_t[1]")

function Path.new(s)
    return PathBuf_ct(s)
end

function Path:to_str()
    local obj = pathify(self)
    local s = plib.path_to_str(obj, temp_len)
    if s == nil then
        error("Path contains invalid data")
    end
    return ffi_string(s, temp_len[0])
end

function Path:is_absolute()
    local obj = pathify(self)
    return plib.path_is_absolute(obj)
end

function Path:is_relative()
    local obj = pathify(self)
    return plib.path_is_relative(obj)
end

function Path:has_root()
    local obj = pathify(self)
    return plib.path_has_root(obj)
end

function Path:starts_with(start)
    local obj = pathify(self)
    start = pathify(start)
    return plib.path_starts_with(obj, start)
end

function Path:ends_with(start)
    local obj = pathify(self)
    start = pathify(start)
    return plib.path_starts_with(obj, start)
end

function Path:exists()
    local obj = pathify(self)
    return plib.path_exists(obj)
end

function Path:is_file()
    local obj = pathify(self)
    return plib.path_is_file(obj)
end

function Path:is_dir()
    local obj = pathify(self)
    return plib.path_is_dir(obj)
end

function Path:parent()
    local obj = pathify(self)
    local new_obj = Path_ct()
    plib.path_parent(obj, new_obj)
    if new_obj._p == 0 then
        return nil
    end
    return new_obj
end

function Path:strip_prefix(prefix)
    local obj = pathify(self)
    prefix = pathify(prefix)
    local suffix = Path_ct()
    plib.path_strip_prefix(obj, prefix, suffix)
    if suffix._p == 0 then
        return nil
    end
    return suffix
end

function Path:file_name()
    local obj = pathify(self)
    local s = plib.path_file_name(obj, temp_len)
    if s == nil then
        error("Path contains invalid data in its file_name")
    end
    return ffi_string(s, temp_len[0])
end

function Path:file_stem()
    local obj = pathify(self)
    local s = plib.path_file_stem(obj, temp_len)
    if s == nil then return nil end
    return ffi_string(s, temp_len[0])
end

function Path:extension()
    local obj = pathify(self)
    local s = plib.path_extension(obj, temp_len)
    if s == nil then return nil end
    return ffi_string(s, temp_len[0])
end

function Path:join(path, ...)
    local left = pathify(self)
    local right = pathify(path)
    local joined = plib.path_join(left, right)
    local buf = ffi_new(PathBuf_ct, joined, false)

    for i, part in ipairs({...}) do
        buf:push(part)
    end

    return buf
end

function Path:with_file_name(name)
    if type(name) ~= 'string' then
        error("Expected string")
    end

    local obj = pathify(self)
    local path = plib.path_with_file_name(obj, name, #name)
    if path == nil then
        error("with_file_name was passed an invalid string")
    end
    return ffi_new(PathBuf_ct, path, false)
end

function Path:with_extension(ext)
    if type(ext) ~= 'string' then
        error("Expected string")
    end

    local obj = pathify(self)
    local path = plib.path_with_extension(obj, ext, #ext)
    if path == nil then
        error("with_extension was passed an invalid string")
    end
    return ffi_new(PathBuf_ct, path, false)
end

function Path:canonicalize()
    local obj = pathify(self)
    local path = plib.path_canonicalize(obj)
    if path == nil then return nil end
    return ffi_new(PathBuf_ct, path, false)
end

function Path:read_link()
    local obj = pathify(self)
    local path = plib.path_read_link(obj)
    if path == nil then return nil end
    return ffi_new(PathBuf_ct, path, false)
end

function Path:metadata()
    local obj = pathify(self)
    local m = plib.path_metadata(obj)
    if m == nil then return nil end
    return FileMeta_ct(m)
end

function Path:symlink_metadata()
    local obj = pathify(self)
    local m = plib.path_symlink_metadata(obj)
    if m == nil then return nil end
    return FileMeta_ct(m)
end

local function walk_iter(state)
    if state == nil then
        return nil
    end

    local ptr = plib.path_read_dir_next(state)
    if ptr == nil then
        return nil
    end
    return ffi_new(PathBuf_ct, ptr, false)
end

function Path:walk()
    local obj = pathify(self)
    local ptr = plib.path_read_dir(obj)
    if ptr ~= nil then
        ptr = ffi.gc(ptr, plib.path_free_read_dir)
    end
    return walk_iter, ptr
end

function Path.copy(from, to)
    from = pathify(from)
    to = pathify(to)
    local bytes = plib.path_copy(from, to)
    if bytes == ffi.cast("uint64_t", -1) then
        return nil
    end
    return bytes
end

function Path.create_dir(path)
    path = pathify(path)
    return plib.path_create_dir(path)
end

function Path.create_dir_all(path)
    path = pathify(path)
    return plib.path_create_dir_all(path)
end

function Path.remove_dir(path)
    path = pathify(path)
    return plib.path_remove_dir(path)
end

function Path.remove_dir_all(path)
    path = pathify(path)
    return plib.path_remove_dir_all(path)
end

function Path.remove_file(path)
    path = pathify(path)
    return plib.path_remove_file(path)
end

function Path.rename(from, to)
    from, to = pathify(from), pathify(to)
    return plib.path_rename(from, to)
end

function Path.hard_link(src, dst)
    src, dst = pathify(src), pathify(dst)
    return plib.path_hard_link(src, dst)
end

function Path.symlink_file(src, dst)
    src, dst = pathify(src), pathify(dst)
    return plib.path_symlink_file(src, dst)
end

function Path.symlink_dir(src, dst)
    src, dst = pathify(src), pathify(dst)
    return plib.path_symlink_dir(src, dst)
end

function Path_mt:__tostring()
    return self:to_str()
end

Path_ct = ffi.metatype("struct PathObj", Path_mt)

----------------------
-- PathBuf functions

-- Inherit all of those Path functions
for k, fn in pairs(Path) do
    if type(k) == 'string' and string.sub(k, 1, 1) ~= '_' then
        PathBuf[k] = fn
    end
end

function PathBuf_mt.__new(tp, path)
    local ptr
    if ffi_istype(PathBuf_ct, path) then
        ptr = plib.path_clone(path._buf)
    elseif ffi_istype(Path_ct, path) then
        ptr = plib.path_buf_from_obj(path)
    elseif type(path) == 'string' then
        ptr = plib.path_create(path, #path)
    end
    if ptr == nil then
        error(string.format("Failed to create a path for %q", tostring(path)))
    end
    return ffi_new(tp, ptr, false)
end

function PathBuf_mt:__gc()
    plib.path_free(self._buf)
end

function PathBuf:clone()
    return PathBuf_ct(self)
end

function PathBuf:push(path)
    path = pathify(path)

    self._has_po = false
    plib.path_push(self._buf, path)
end

function PathBuf:pop()
    self._has_po = false
    return plib.path_pop(self._buf)
end

function PathBuf:set_file_name(name)
    if type(name) ~= 'string' then
        error("Wrong type passed to PathBuf:set_file_name()")
    end

    self._has_po = false
    assert(plib.path_set_file_name(self._buf, name, #name))
end

function PathBuf:set_extension(ext)
    if type(ext) ~= 'string' then
        error("Wrong type passed to PathBuf:set_extension()")
    end

    self._has_po = false
    assert(plib.path_set_extension(self._buf, ext, #ext))
end

function PathBuf_mt:__tostring()
    return self:to_str()
end

PathBuf_ct = ffi.metatype("struct PathBuf", PathBuf_mt)

function FileMeta_mt:__gc()
    plib.path_free_metadata(self._meta)
end

function FileMeta:file_type()
    local type = plib.path_meta_file_type(self._meta)
    if type == plib.FT_File then
        return 'file'
    elseif type == plib.FT_Dir then
        return 'dir'
    elseif type == plib.FT_SymLink then
        return 'symlink'
    else
        return 'other'
    end
end

function FileMeta:is_file()
    return plib.path_meta_is_file(self._meta)
end

function FileMeta:is_dir()
    return plib.path_meta_is_dir(self._meta)
end

function FileMeta:file_size()
    return plib.path_meta_file_size(self._meta)
end

function FileMeta:modified()
    return plib.path_meta_modified(self._meta)
end

function FileMeta:accessed()
    return plib.path_meta_modified(self._meta)
end

function FileMeta:created()
    return plib.path_meta_modified(self._meta)
end

FileMeta_ct = ffi.metatype("struct FileMeta", FileMeta_mt)

Path.PathBuf = PathBuf
return Path
