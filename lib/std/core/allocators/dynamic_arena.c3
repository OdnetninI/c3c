// Copyright (c) 2021 Christoffer Lerno. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.
module std::core::mem::allocator;

struct DynamicArenaAllocator
{
	inline Allocator allocator;
	Allocator* backing_allocator;
	DynamicArenaPage* page;
	DynamicArenaPage* unused_page;
	usz page_size;
}

/**
 * @require page_size >= 128
 **/
fn void DynamicArenaAllocator.init(&self, usz page_size, Allocator* using = mem::heap())
{
	self.function = &dynamic_arena_allocator_function;
	self.page = null;
	self.unused_page = null;
	self.page_size = page_size;
	self.backing_allocator = using;
}

fn void DynamicArenaAllocator.free(&self)
{
	DynamicArenaPage* page = self.page;
	while (page)
	{
		DynamicArenaPage* next_page = page.prev_arena;
		free(page, .using = self.backing_allocator);
		page = next_page;
	}
	page = self.unused_page;
	while (page)
	{
		DynamicArenaPage* next_page = page.prev_arena;
		free(page, .using = self.backing_allocator);
		page = next_page;
	}
	self.page = null;
	self.unused_page = null;
}

struct DynamicArenaPage @local
{
	void* memory;
	void* prev_arena;
	usz total;
	usz used;
	void* current_stack_ptr;
}

struct DynamicArenaChunk @local
{
	usz size;
}

/**
 * @require ptr
 * @require self.page `tried to free pointer on invalid allocator`
 */
fn void DynamicArenaAllocator.free_ptr(&self, void* ptr) @local
{
	DynamicArenaPage* current_page = self.page;
	if (ptr == current_page.current_stack_ptr)
	{
		current_page.used = (usz)((ptr - DEFAULT_SIZE_PREFIX) - current_page.memory);
	}
	current_page.current_stack_ptr = null;
}

/**
 * @require old_pointer && size > 0
 * @require self.page `tried to realloc pointer on invalid allocator`
 */
fn void*! DynamicArenaAllocator._realloc(&self, void* old_pointer, usz size, usz alignment, usz offset) @local
{
	DynamicArenaPage* current_page = self.page;
	alignment = alignment_for_allocation(alignment);
	usz* old_size_ptr = old_pointer - DEFAULT_SIZE_PREFIX;
	usz old_size = *old_size_ptr;
	// We have the old pointer and it's correctly aligned.
	if (old_size >= size && mem::ptr_is_aligned(old_pointer, alignment))
	{
		*old_size_ptr = size;
		if (current_page.current_stack_ptr == old_pointer)
		{
			current_page.used = (usz)((old_pointer - DEFAULT_SIZE_PREFIX) - current_page.memory);
		}
		return old_pointer;
	}
	if REUSE: (current_page.current_stack_ptr == old_pointer && mem::ptr_is_aligned(old_pointer, alignment))
	{
		assert(size > old_size);
		usz add_size = size - old_size;
		if (add_size + current_page.used > current_page.total) break REUSE;
		*old_size_ptr = size;
		current_page.used += add_size;
		return old_pointer;
	}
	void* new_mem = self._alloc(size, alignment, offset)!;
	mem::copy(new_mem, old_pointer, old_size, mem::DEFAULT_MEM_ALIGNMENT);
	return new_mem;
}

fn void DynamicArenaAllocator.reset(&self) @private
{
	DynamicArenaPage* page = self.page;
	DynamicArenaPage** unused_page_ptr = &self.unused_page;
	while (page)
	{
		DynamicArenaPage* next_page = page.prev_arena;
		page.used = 0;
		DynamicArenaPage* prev_unused = *unused_page_ptr;
		*unused_page_ptr = page;
		page.prev_arena = prev_unused;
		page = next_page;
	}
	self.page = page;
}

/**
 * @require math::is_power_of_2(alignment)
 * @require size > 0
 */
fn void*! DynamicArenaAllocator._alloc_new(&self, usz size, usz alignment, usz offset) @local
{
	// First, make sure that we can align it, extending the page size if needed.
	usz page_size = max(self.page_size, mem::aligned_offset(size + DynamicArenaChunk.sizeof + offset, alignment) - offset);

	// Grab the page without alignment (we do it ourselves)
	void* mem = self.backing_allocator.alloc(page_size)!;
	DynamicArenaPage*! page = malloc(DynamicArenaPage, .using = self.backing_allocator);
	if (catch err = page)
	{
		free(mem, .using = self.backing_allocator);
		return err?;
	}
	page.memory = mem;
	void* mem_start = mem::aligned_pointer(mem + offset + DynamicArenaChunk.sizeof, alignment) - offset;
	assert(mem_start + size < mem + page_size);
	DynamicArenaChunk* chunk = (DynamicArenaChunk*)mem_start - 1;
	chunk.size = size;
	page.prev_arena = self.page;
	page.total = page_size;
	page.used = mem_start + size - page.memory;
	self.page = page;
	page.current_stack_ptr = mem_start;
	return mem_start;
}

/**
 * @require !alignment || math::is_power_of_2(alignment)
 * @require size > 0
 */
fn void*! DynamicArenaAllocator._alloc(&self, usz size, usz alignment, usz offset) @local
{
	alignment = alignment_for_allocation(alignment);
	DynamicArenaPage* page = self.page;
	if (!page && self.unused_page)
	{
		self.page = page = self.unused_page;
		self.unused_page = page.prev_arena;
		page.prev_arena = null;
	}
	if (!page) return self._alloc_new(size, alignment, offset);
	void* start = mem::aligned_pointer(page.memory + page.used + DynamicArenaChunk.sizeof + offset, alignment) - offset;
	usz new_used = start - page.memory + size;
	if ALLOCATE_NEW: (new_used > page.total)
	{
		if ((page = self.unused_page))
		{
			start = mem::aligned_pointer(page.memory + page.used + DynamicArenaChunk.sizeof + offset, alignment) - offset;
			new_used = start + size - page.memory;
			if (page.total >= new_used)
			{
				self.unused_page = page.prev_arena;
				page.prev_arena = self.page;
				self.page = page;
				break ALLOCATE_NEW;
			}
		}
		return self._alloc_new(size, alignment, offset);
	}

	page.used = new_used;
	assert(start + size == page.memory + page.used);
	void* mem = start;
	DynamicArenaChunk* chunk = (DynamicArenaChunk*)mem - 1;
	chunk.size = size;
	return mem;
}

/**
 * @require !alignment || math::is_power_of_2(alignment)
 * @require data `unexpectedly missing the allocator`
 */
fn void*! dynamic_arena_allocator_function(Allocator* data, usz size, usz alignment, usz offset, void* old_pointer, AllocationKind kind) @private
{
	DynamicArenaAllocator* allocator = (DynamicArenaAllocator*)data;
	switch (kind)
	{
		case CALLOC:
		case ALIGNED_CALLOC:
			assert(!old_pointer, "Unexpected no old pointer for calloc.");
			if (!size) return null;
			void* mem = allocator._alloc(size, alignment, offset)!;
			mem::clear(mem, size, mem::DEFAULT_MEM_ALIGNMENT);
			return mem;
		case ALLOC:
		case ALIGNED_ALLOC:
			assert(!old_pointer, "Unexpected no old pointer for alloc.");
			if (!size) return null;
			return allocator._alloc(size, alignment, offset);
		case REALLOC:
		case ALIGNED_REALLOC:
			if (!size)
			{
				if (!old_pointer) return null;
				allocator.free_ptr(old_pointer);
				return null;
			}
			if (!old_pointer) return allocator._alloc(size, alignment, offset);
			void* mem = allocator._realloc(old_pointer, size, alignment, offset)!;
			return mem;
		case ALIGNED_FREE:
		case FREE:
			if (!old_pointer) return null;
			allocator.free_ptr(old_pointer);
			return null;
		case MARK:
			unreachable("Tried to mark a dynamic arena");
		case RESET:
			allocator.reset();
			return null;
	}
}
