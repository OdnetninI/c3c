// https://www.cprogramming.com/snippets/source-code/find-the-number-of-cpu-cores-for-windows-mac-or-linux

module std::os @if(env::DARWIN);
import std::os::macos;

fn uint num_cpu()
{
	int[2] nm;
	usz len = 4;
	uint count;

	nm = { macos::CTL_HW, macos::HW_NCPU };
	macos::sysctl(&nm, 2, &count, &len, null, 0);
	if (count < 1) count = 1;
	return count;
}

module std::os @if(env::LINUX);
import std::os::posix;

fn uint num_cpu()
{
	return posix::get_nprocs_conf();
}

module std::os @if(env::WIN32);
import std::os::win32;

fn uint num_cpu()
{
	SystemInfo info;
	win32::get_system_info(&info);
	return info.dwNumberOfProcessors;
}