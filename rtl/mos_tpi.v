// MOS6523/6525 TPI

module mos_tpi (
  input  wire       mode,   // 0 - 6523, 1 - 6525
  input  wire       clk,
  input  wire       res_n,
  input  wire       cs_n,
  input  wire       rw,

  input  wire [2:0] rs,
  input  wire [7:0] db_in,
  output reg  [7:0] db_out,

  input  wire [7:0] pa_in,
  output wire [7:0] pa_out,
  output wire [7:0] pa_oe,

  input  wire [7:0] pb_in,
  output wire [7:0] pb_out,
  output wire [7:0] pb_oe,

  input  wire [7:0] pc_in,
  output wire [7:0] pc_out,
  output wire [7:0] pc_oe
);

// Internal Registers
reg [7:0] pra;
reg [7:0] prb;
reg [7:0] prc;
reg [7:0] ddra;
reg [7:0] ddrb;
reg [7:0] ddrc;

reg [1:0] crcb;
reg [1:0] crca;
reg [1:0] ie;
reg       ip;
reg       mc_r;

reg       cb;
reg       ca;

reg       irq_n;
reg [4:0] ilr;
reg [4:0] air;
reg [4:0] mr;

wire      rd = !cs_n & rw;
wire      wr = !cs_n & !rw;
wire      mc = mode & mc_r;

// Register Decoding
always @(posedge clk) begin
  if (!res_n) 
    db_out <= 8'h00;
  else if (rd)
    case (rs)
      0: db_out <= pa_in;
      1: db_out <= pb_in;
      2: db_out <= mc ? {cb, ca, irq_n, ilr} : pc_in;
      3: db_out <= ddra;
      4: db_out <= ddrb;
      5: db_out <= mc ? {3'b111, mr} : ddrc;
      6: db_out <= mode ? {crcb, crca, ie, ip, mc} : 8'hff;
      7: db_out <= mode ? {3'b111, air} : 8'hff;
    endcase
end

assign pa_oe = ddra;
assign pb_oe = ddrb;
assign pc_oe = mc ? 8'b11100000 : ddrc;

assign pa_out = pra | ~ddra;
assign pb_out = prb | ~ddrb;
assign pc_out = mode && mc ? {cb, ca, irq_n, 5'b11111} : prc | ~ddrc;

// Port A Output
always @(posedge clk) begin
  if (!res_n) begin
    pra  <= 8'h00;
    ddra <= 8'h00;
  end
  else if (wr)
    case (rs)
      0: pra  <= db_in;
      3: ddra <= db_in;
      default: ;
    endcase
end

// Port B Output
always @(posedge clk) begin
  if (!res_n) begin
    prb  <= 8'h00;
    ddrb <= 8'h00;
  end
  else if (wr)
    case (rs)
      1: prb  <= db_in;
      4: ddrb <= db_in;
      default: ;
    endcase
end


// Port C Output
always @(posedge clk) begin
  if (!res_n) begin
    prc  <= 8'h00;
    ddrc <= 8'h00;
  end
  else if (wr)
    case (rs)
      2: prc  <= db_in;
      5: ddrc <= db_in;
      default: ;
    endcase
end

// Interrupt control
always @(posedge clk) begin
  reg [4:0] pc_in_r;
  reg [5:0] pulsecnt;

  pc_in_r <= pc_in[4:0];

  if (!res_n) begin
    irq_n <= 1'b1;
    ilr   <= 0;
    air   <= 0;
    crcb  <= 2'b00;
    crca  <= 2'b00;
    ca    <= 1'b0;
    cb    <= 1'b0;
    ie    <= 1'b0;
    ip    <= 1'b0;
    mc_r  <= 1'b0;
    pulsecnt <= 0;
  end
  else if (mode) begin
    if (pulsecnt > 0) begin
      pulsecnt <= pulsecnt - 1'b1;
      if (pulsecnt == 1) begin
        if (crca == 1) ca <= 1'b1;
        if (crcb == 1) cb <= 1'b1;
      end
    end

    if (wr && rs == 6) begin
      {crcb, crca, ie, ip, mc_r} <= db_in;
      ca <= db_in[4];
      cb <= db_in[6];
    end
    else if (mc) begin
      if (rd) begin
        case (rs) 
          0: if (!crca[1]) begin
              ca <= 1'b0;
              if (!crca[0]) pulsecnt <= 17;
            end
          1: if (!crcb[1]) begin
              cb <= 1'b0;
              if (!crcb[0]) pulsecnt <= 17;
            end
          default: ;
        endcase
      end 
      else if (wr) begin
        case (rs)
          2: ilr <= ilr & db_in[4:0];
          5: mr  <= db_in[4:0];
          7: air <= db_in[4:0];
          default: ;
        endcase
      end
      else begin
        if (pc_in[0] && !pc_in_r[0]) begin
          ilr[0] <= 1'b1;
        end
        if (pc_in[1] && !pc_in_r[1]) begin
          ilr[1] <= 1'b1;
        end
        if (pc_in[2] && !pc_in_r[2]) begin
          ilr[2] <= 1'b1;
        end
        if ((pc_in[3]^ie[0]) && !(pc_in_r[3]^ie[0])) begin
          ilr[3] <= 1'b1;
          if (crca == 0) ca <= 1'b1;
        end
        if ((pc_in[4]^ie[1]) && !(pc_in_r[4]^ie[1])) begin
          ilr[4] <= 1'b1;
          if (crcb == 0) cb <= 1'b1;
        end
      end
    end 
  end
end


endmodule
