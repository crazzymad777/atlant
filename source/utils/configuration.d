module atlant.utils.configuration;

struct Configuration
{
    string workingDirectory;
    bool enableDirectoryList; // bool showDirectoryContents;
    bool lazyLoad;
    int port; // bind addresses...
}

private void parseOption(Configuration* conf, string pair)
{
    import std.array: split;
    import std.uni: toLower;
    auto parts = split(pair, '=');
    if (parts.length != 2) return;

    auto x = toLower(parts[0]);
    if (x == "override_directory")
    {
        conf.workingDirectory = parts[1];
        return;
    }

    if (x == "directory_list")
    {
        conf.enableDirectoryList = parseBool(parts[1], conf.enableDirectoryList);
        return;
    }

    if (x == "lazy_load")
    {
        conf.lazyLoad = parseBool(parts[1], conf.lazyLoad);
        return;
    }
}

private bool parseBool(string flag, bool def)
{
    import std.uni: toLower;
    flag = toLower(flag);
    if (flag == "1" || flag == "y" || flag == "true" || flag == "yes" || flag == "t")
	{
		return true;
	}

	if (flag == "0" || flag == "n" || flag == "false" || flag == "no" || flag == "f")
	{
		return false;
	}
    return def;
}

Configuration defaultConfiguration()
{
    import std.process: environment;
	import std.file: getcwd;
	import std.conv;
    Configuration conf;
    conf.workingDirectory = environment.get("ATLANT_OVERRIDE_DIRECTORY");
	if (conf.workingDirectory is null)
	{
		conf.workingDirectory = getcwd();
	}
    conf.enableDirectoryList = parseBool(environment.get("ATLANT_DIRECTORY_LIST"), false);

	// Non-cannonical mode
	conf.lazyLoad = parseBool(environment.get("ATLANT_LAZY_LOAD"), false);

	string strPort = environment.get("ATLANT_HTTP_PORT", "80");
    conf.port = parse!int(strPort);
    return conf;
}

void parseArgs(Configuration* conf, string[] args)
{
    import std.stdio;
    enum Option
    {
        None,
        WorkingDirectory,
        Option
    };

    Option next = Option.None;
    bool nextValue = false;
    import core.stdc.stdlib: exit;
    import std.path: baseName;

    for (int i = 1; i < args.length; i++)
    {
        if (nextValue)
        {
            if (next == Option.WorkingDirectory)
            {
                conf.workingDirectory = args[i];
            }
            else if (next == Option.Option)
            {
                parseOption(conf, args[i]);
            }

            next = Option.None;
            nextValue = false;
            continue;
        }

        if (args[i] == "--help" || args[i] == "-h")
        {
            writeln("Use: ", baseName(args[0]), " [OPTIONS]");
            writeln("-h, --help - show this help message");
            writeln("-l, --lazy - enable lazy mode, cache on request");
            writeln("-w, --working-directory - set application root directory");
            writeln("-o, --option key=value - set option");
            writeln("Available keys:");
            writeln("override_directory - same as --working-directory");
            writeln("directory_list - show users directory content");
            writeln("lazy_load - same as --lazy");
            exit(0);
        }

        if (args[i] == "-l" || args[i] == "--lazy")
        {
            conf.lazyLoad = true;
        }

        if (args[i] == "-w" || args[i] == "--working-directory")
        {
            nextValue = true;
            next = Option.WorkingDirectory;
        }

        if (args[i] == "-o" || args[i] == "--option")
        {
            nextValue = true;
            next = Option.Option;
        }
    }
}
