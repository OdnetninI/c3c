module std::os::macos @if(env::DARWIN);

const CTL_UNSPEC	= 0; /* unused */
const CTL_KERN		= 1; /* "high kernel": proc, limits */
const CTL_VM		= 2; /* virtual memory */
const CTL_VFS		= 3; /* file system, mount type is next */
const CTL_NET		= 4; /* network, see socket.h */
const CTL_DEBUG		= 5; /* debugging parameters */
const CTL_HW		= 6; /* generic cpu/io */
const CTL_MACHDEP	= 7; /* machine dependent */
const CTL_USER		= 8; /* user-level */
const CTL_MAXID		= 9; /* number of valid top-level ids */

const HW_MACHINE		= 1; /* string: machine class */
const HW_MODEL			= 2; /* string: specific machine model */
const HW_NCPU			= 3; /* int: number of cpus */
const HW_BYTEORDER		= 4; /* int: machine byte order */
const HW_PHYSMEM		= 5; /* int: total memory */
const HW_USERMEM		= 6; /* int: non-kernel memory */
const HW_PAGESIZE		= 7; /* int: software page size */
const HW_DISKNAMES		= 8; /* strings: disk drive names */
const HW_DISKSTATS		= 9; /* struct: diskstats[] */
const HW_EPOCH			= 10; /* int: 0 for Legacy, else NewWorld */
const HW_FLOATINGPT		= 11; /* int: has HW floating point? */
const HW_MACHINE_ARCH	= 12; /* string: machine architecture */
const HW_VECTORUNIT		= 13; /* int: has HW vector unit? */
const HW_BUS_FREQ		= 14; /* int: Bus Frequency */
const HW_CPU_FREQ		= 15; /* int: CPU Frequency */
const HW_CACHELINE		= 16; /* int: Cache Line Size in Bytes */
const HW_L1ICACHESIZE	= 17; /* int: L1 I Cache Size in Bytes */
const HW_L1DCACHESIZE	= 18; /* int: L1 D Cache Size in Bytes */
const HW_L2SETTINGS		= 19; /* int: L2 Cache Settings */
const HW_L2CACHESIZE	= 20; /* int: L2 Cache Size in Bytes */
const HW_L3SETTINGS		= 21; /* int: L3 Cache Settings */
const HW_L3CACHESIZE	= 22; /* int: L3 Cache Size in Bytes */
const HW_MAXID			= 23; /* number of valid hw ids */

extern fn CInt sysctl(CInt *name, CUInt namelen, void *oldp, usz *oldlenp, void *newp, usz newlen);
