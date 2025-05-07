module atlant.main;

extern(C) void main()
{
    import atlant.utils.string;
    import core.stdc.stdio;
    printf("%ld\n", String.sizeof);
}
