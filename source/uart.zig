const uno = @import("uno.zig");
const regs = @import("atmega328p.zig").registers;

pub fn init(comptime baud: comptime_int) void {
    // Set baudrate
    regs.USART0.UBRR0.* = (uno.CPU_FREQ / (8 * baud)) - 1;

    // Default uart settings are 8n1, so no need to change them!
    regs.USART0.UCSR0A.modify(.{ .U2X0 = 1 });

    // Enable transmitter!
    regs.USART0.UCSR0B.modify(.{ .TXEN0 = 1 });
}

pub fn writeString(s: []const u8) void {
    for (s) |ch| {
        writeByte(ch);
    }

    // Wait till we are actually done sending
    while (regs.USART0.UCSR0A.read().TXC0 != 1) {}
}

pub fn writeByte(byte: u8) void {
    // Wait till the transmit buffer is empty
    while (regs.USART0.UCSR0A.read().UDRE0 != 1) {}

    regs.USART0.UDR0.* = byte;
}

pub fn writeLine(s: ?[]const u8) void {
    if(s) |v| {
        writeString(v);
    }
    writeString("\r\n");
}
