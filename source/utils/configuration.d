module atlant.utils.configuration;

shared Configuration configuration;

struct Configuration
{
    bool defaultIndex;
    string[] index;
    string workingDirectory;
    bool enableDirectoryList; // bool showDirectoryContents;
    bool lazyLoad;
    string[] bindAddresses;
    bool defaultBindAddresses;
    int port;
}

public Configuration getGlobalConfiguration()
{
    return configuration;
}

public Configuration setGlobalConfiguration(Configuration conf)
{
    configuration = conf;
}

private void parseOption(Configuration* conf, string pair)
{
    import std.array: split;
    import std.uni: toLower;
    import std.conv;

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

    if (x == "http_bind")
    {
        if (conf.defaultBindAddresses)
        {
            conf.bindAddresses = [];
            conf.defaultBindAddresses = false;
        }

        auto newAddrs = split(parts[1]);
        conf.bindAddresses ~= newAddrs;
        return;
    }

    if (x == "add_index")
    {
        if (conf.defaultIndex)
        {
            conf.index = [];
            conf.defaultIndex = false;
        }

        auto newIndex = split(parts[1]);
        conf.index ~= newIndex;
        return;
    }

    if (x == "http_port")
    {
        conf.port = parse!int(parts[1]);
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
    import std.array: split;
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

    string bindAddresses = environment.get("ATLANT_HTTP_BIND_ADDRESSES");
    if (bindAddresses is null)
    {
        bindAddresses = "0.0.0.0,::";
        conf.defaultBindAddresses = true;
    }
    else
    {
        conf.defaultBindAddresses = false;
    }
    conf.bindAddresses = split(bindAddresses, ',');

    string indexFiles = environment.get("ATLANT_INDEX");
    if (indexFiles is null)
    {
        indexFiles = "index.html,index.htm";
        conf.defaultIndex = true;
    }
    else
    {
        conf.defaultIndex = false;
    }
    conf.index = split(indexFiles, ',');
    return conf;
}

void parseArgs(Configuration* conf, string[] args)
{
    import std.array: split;
    import std.stdio;
    enum Option
    {
        None,
        WorkingDirectory,
        Option,
        HttpBindAddress,
        Port,
        AddIndex
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
            else if (next == Option.HttpBindAddress)
            {
                if (conf.defaultBindAddresses)
                {
                    conf.bindAddresses = [];
                    conf.defaultBindAddresses = false;
                }

                auto newAddrs = split(args[i]);
                conf.bindAddresses ~= newAddrs;
            }
            else if (next == Option.Port)
            {
                import std.conv: parse;
                conf.port = parse!int(args[i]);
            }
            else if (next == Option.AddIndex)
            {
                if (conf.defaultIndex)
                {
                    conf.index = [];
                    conf.defaultIndex = false;
                }

                auto newIndex = split(args[i]);
                conf.index ~= newIndex;
                return;
            }

            next = Option.None;
            nextValue = false;
            continue;
        }

        if (args[i] == "--help" || args[i] == "-h")
        {
            writeln("Use: ", baseName(args[0]), " [OPTIONS]");
            writeln("-a, --add-address - add bind address(-es) comma-separated");
            writeln("-h, --help - show this help message");
            writeln("-l, --lazy - enable lazy mode, cache on request");
            writeln("-p, --port - specify HTTP PORT");
            writeln("-w, --working-directory - set application root directory");
            writeln("-x, --add-index - define files which will be used as an index");
            writeln("-o, --option key=value - set option");
            writeln("Available keys:");
            writeln("add_index - same as --add-index");
            writeln("directory_list - show users directory content");
            writeln("http_bind - same as --add-address");
            writeln("http_port - same as --port");
            writeln("lazy_load - same as --lazy");
            writeln("override_directory - same as --working-directory");
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

        if (args[i] == "-p" || args[i] == "--port")
        {
            nextValue = true;
            next = Option.Port;
        }

        if (args[i] == "-a" || args[i] == "--add-address")
        {
            nextValue = true;
            next = Option.HttpBindAddress;
        }

        if (args[i] == "-x" || args[i] == "--add-index")
        {
            nextValue = true;
            next = Option.AddIndex;
        }
    }
}
