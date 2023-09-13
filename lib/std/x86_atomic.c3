module std::atomic @if(env::X86_64);

/**
 * @param [&inout] ptr "the variable or dereferenced pointer to the data."
 * @param [inout] y "the value to be added to ptr."
 * @param $ordering "atomic ordering of the load, defaults to SEQ_CONSISTENT"
 * @return "returns the old value of ptr"
 * 
 * @require types::is_int($typeof(*ptr)) || types::is_float($typeof(*ptr)) "Only integer/float pointers may be used."
 * @require $ordering != AtomicOrdering.NOT_ATOMIC && $ordering != AtomicOrdering.UNORDERED "Acquire ordering is not valid."
 **/
macro fetch_add(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT)
{
	var $load_ordering = $ordering;
	$if $ordering == RELEASE || $ordering == ACQUIRE_RELEASE:
	    $load_ordering = AtomicOrdering.SEQ_CONSISTENT;
	$endif

  $if types::is_float($typeof(*ptr)):
    return fetch_add_generic(ptr, y, $ordering);
  $endif
	
  $switch ($typeof(*ptr))
    $case char:
    $case ichar:
      asm {
        lock;
        xaddb [ptr], y;
      };
    $case short:
    $case ushort:
      asm {
        lock;
        xaddw [ptr], y;
      };
    $case int:
    $case uint:
      asm {
        lock;
        xaddl [ptr], y;
      };
    $case long:
    $case ulong:
      asm {
        lock;
        xaddq [ptr], y;
      };
    $default: assert(false, "Integer pointer not recognized");
  $endswitch

	return y;
}


module std::atomic @if(!env::X86_64);

/**
 * @param [&in] ptr "the variable or dereferenced pointer to the data."
 * @param [in] y "the value to be added to ptr."
 * @param $ordering "atomic ordering of the load, defaults to SEQ_CONSISTENT"
 * @return "returns the old value of ptr"
 * 
 * @require types::is_int($typeof(*ptr)) || types::is_float($typeof(*ptr)) "Only integer/float pointers may be used."
 * @require $ordering != AtomicOrdering.NOT_ATOMIC && $ordering != AtomicOrdering.UNORDERED "Acquire ordering is not valid."
 **/
macro fetch_add(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT)
{
	return fetch_add_generic(ptr, y, $ordering);
}
