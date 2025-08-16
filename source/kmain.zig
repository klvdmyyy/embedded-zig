//! Kernel main function.

const uart = @import("uart.zig");

// This is put in the data section
var ch: u8 = '!';

// This ends up in the bss section
var bss_stuff: [9]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };

// Put public functions here named after interrupts to instantiate them as
// interrupt handlers. If you name one incorrectly you'll get a compiler error
// with the full list of options.
pub const interrupts = struct {
    // Pin Change Interrupt Source 0
    // pub fn PCINT0() void {}
};

pub export fn kmain() noreturn {
    uart.init(9600);
    uart.writeString("Kernel successfully loaded.");
    while(true) {}
}

fn delayCycles(cycles: u32) void {
    var count: u32 = 0;
    while (count < cycles) : (count += 1) {
        asm volatile ("nop");
    }
}
