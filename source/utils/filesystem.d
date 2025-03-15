module atlant.utils.filesystem;

import std.process: execute;

string get_file_mime(string path)
{
    import std.string: strip;
    auto result = execute(["file", "-ibL", path]);
    return strip(result.output);
}

bool fexists(string path)
{
    import std.file: exists;
    return exists(path);
}
