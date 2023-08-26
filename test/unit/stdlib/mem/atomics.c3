import std::thread;
import std::io;

uint a;

fn void! inc() @test @if(env::X86_64)
{
	Thread[100] ts;
	a = 0;
	foreach (&t : ts)
	{
		t.create(fn int(void* arg) {
      thread::sleep_ms(5);
			@atomic_increment(a);
      thread::sleep_ms(5);
      @atomic_increment(a);
      thread::sleep_ms(5);
      @atomic_increment(a);
      thread::sleep_ms(5);
      @atomic_increment(a);
      thread::sleep_ms(5);
      @atomic_increment(a);
      thread::sleep_ms(5);
      @atomic_increment(a);
		    return 0;
		}, null)!;
	}
	foreach (&t : ts)
    {
        assert(t.join()! == 0);
    }
	assert(a == ts.len * 6, "Threads returned %d, expected %d", a, ts.len * 6);
}

fn void! add() @test @if(env::X86_64)
{
	Thread[100] ts;
	a = 0;
	foreach (&t : ts)
	{
		t.create(fn int(void* arg) {
      thread::sleep_ms(5);
			@atomic_add(a, 5);
      thread::sleep_ms(5);
      @atomic_add(a, 5);
      thread::sleep_ms(5);
      @atomic_add(a, 5);
      thread::sleep_ms(5);
      @atomic_add(a, 5);
      thread::sleep_ms(5);
      @atomic_add(a, 5);
      thread::sleep_ms(5);
      @atomic_add(a, 5);
		    return 0;
		}, null)!;
	}
	foreach (&t : ts)
    {
        assert(t.join()! == 0);
    }
	assert(a == ts.len * 6 * 5, "Threads returned %d, expected %d", a, ts.len * 6 * 5);
}


