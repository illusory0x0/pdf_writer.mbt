///|
impl @fmt.Format for GraphicsOp with write(
  value : GraphicsOp,
  buffer : @fmt.Memory,
  start : Int,
) -> Int {
  try {
    match value {
      Op_w(w) => @fmt.format_write(" {} w", [w], buffer, start)
      Op_J(j) => @fmt.format_write(" {} J", [j], buffer, start)
      Op_j(j) => @fmt.format_write(" {} j", [j], buffer, start)
      Op_M(m) => @fmt.format_write(" {} M", [m], buffer, start)
      Op_cm(t) =>
        @fmt.format_write(
          " {} {} {} {} {} {} cm",
          [t.a, t.b, t.c, t.d, t.e, t.f],
          buffer,
          start,
        )
      Op_BT => @fmt.format_write(" BT", [], buffer, start)
      Op_ET => @fmt.format_write(" ET", [], buffer, start)
      Op_Tf(k, s) => @fmt.format_write(" {} {} Tf", [k[:], s], buffer, start)
      Op_Tj(s) => @fmt.format_write(" ({}) Tj", [s[:]], buffer, start)
      Op_d(fl, y) => {
        let mut offset = start
        for f in fl {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" {} d", [y], buffer, offset)
        offset - start
      }
      Op_ri(s) => @fmt.format_write(" {} ri", [s[:]], buffer, start)
      Op_i(i) => @fmt.format_write(" {} i", [i], buffer, start)
      Op_gs(s) => @fmt.format_write(" {} gs", [s[:]], buffer, start)
      Op_q => @fmt.format_write(" q", [], buffer, start)
      Op_Q => @fmt.format_write(" Q", [], buffer, start)
      Op_m(a, b) => @fmt.format_write(" {} {} m", [a, b], buffer, start)
      Op_l(a, b) => @fmt.format_write(" {} {} l", [a, b], buffer, start)
      Op_c(a, b, c, d, e, k) =>
        @fmt.format_write(
          " {} {} {} {} {} {} c",
          [a, b, c, d, e, k],
          buffer,
          start,
        )
      Op_v(a, b, c, d) =>
        @fmt.format_write(" {} {} {} {} v", [a, b, c, d], buffer, start)
      Op_y(a, b, c, d) =>
        @fmt.format_write(" {} {} {} {} y", [a, b, c, d], buffer, start)
      Op_h => @fmt.format_write(" h", [], buffer, start)
      Op_re(a, b, c, d) =>
        @fmt.format_write(" {} {} {} {} re", [a, b, c, d], buffer, start)
      Op_S => @fmt.format_write(" S", [], buffer, start)
      Op_s => @fmt.format_write(" s", [], buffer, start)
      Op_f => @fmt.format_write(" f", [], buffer, start)
      Op_F => @fmt.format_write(" F", [], buffer, start)
      Op_f_star => @fmt.format_write(" f*", [], buffer, start)
      Op_B => @fmt.format_write(" B", [], buffer, start)
      Op_B_star => @fmt.format_write(" B*", [], buffer, start)
      Op_b => @fmt.format_write(" b", [], buffer, start)
      Op_b_star => @fmt.format_write(" b*", [], buffer, start)
      Op_n => @fmt.format_write(" n", [], buffer, start)
      Op_W => @fmt.format_write(" W", [], buffer, start)
      Op_W_star => @fmt.format_write(" W*", [], buffer, start)
      Op_Tc(c) => @fmt.format_write(" {} Tc", [c], buffer, start)
      Op_Tw(w) => @fmt.format_write(" {} Tw", [w], buffer, start)
      Op_Tz(z) => @fmt.format_write(" {} Tz", [z], buffer, start)
      Op_TL(l) => @fmt.format_write(" {} TL", [l], buffer, start)
      Op_Tr(i) => @fmt.format_write(" {} Tr", [i], buffer, start)
      Op_Ts(r) => @fmt.format_write(" {} Ts", [r], buffer, start)
      Op_Td(k, k_) => @fmt.format_write(" {} {} Td", [k, k_], buffer, start)
      Op_TD(k, k_) => @fmt.format_write(" {} {} TD", [k, k_], buffer, start)
      Op_Tm(t) =>
        @fmt.format_write(
          " {} {} {} {} {} {} Tm",
          [t.a, t.b, t.c, t.d, t.e, t.f],
          buffer,
          start,
        )
      Op_T_star => @fmt.format_write(" T*", [], buffer, start)
      Op_TJ(obj) => {
        let mut offset = start
        offset += @fmt.Format::write(b" ", buffer, offset)
        offset += @fmt.Format::write(obj, buffer, offset)
        offset += @fmt.Format::write(b" TJ", buffer, offset)
        offset - start
      }
      Op_single_quote(s) => @fmt.format_write(" {}'", [s[:]], buffer, start)
      Op_double_quote(k, k_, s) =>
        @fmt.format_write(" {} {} {} \"", [k, k_, s[:]], buffer, start)
      Op_d0(k, k_) => @fmt.format_write(" {} {} d0", [k, k_], buffer, start)
      Op_d1(a, b, c, d, e, k) =>
        @fmt.format_write(
          " {} {} {} {} {} {} d1",
          [a, b, c, d, e, k],
          buffer,
          start,
        )
      Op_CS(s) => @fmt.format_write(" {} CS", [s[:]], buffer, start)
      Op_cs(s) => @fmt.format_write(" {} cs", [s[:]], buffer, start)
      Op_SC(fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" SC", [], buffer, offset)
        offset - start
      }
      Op_SCN(fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" SCN", [], buffer, offset)
        offset - start
      }
      Op_scn(fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" scn", [], buffer, offset)
        offset - start
      }
      Op_scnName(s, fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" {} scn", [s[:]], buffer, offset)
        offset - start
      }
      Op_SCNName(s, fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" {} SCN", [s[:]], buffer, offset)
        offset - start
      }
      Op_G(k) => @fmt.format_write(" {} G", [k], buffer, start)
      Op_g(k) => @fmt.format_write(" {} g", [k], buffer, start)
      Op_RG(r, g, b) =>
        @fmt.format_write(" {} {} {} Rg", [r, g, b], buffer, start)
      Op_rg(r, g, b) =>
        @fmt.format_write(" {} {} {} rg", [r, g, b], buffer, start)
      Op_K(c, m, y, k) =>
        @fmt.format_write(" {} {} {} {} K", [c, m, y, k], buffer, start)
      Op_k(c, m, y, k) =>
        @fmt.format_write(" {} {} {} {} k", [c, m, y, k], buffer, start)
      Op_sh(s) => @fmt.format_write(" {} sh", [s[:]], buffer, start)
      InlineImage(dict, dp, data) => abort("TODO")
      Op_Do(s) => @fmt.format_write(" {} Do", [s[:]], buffer, start)
      Op_MP(s) => @fmt.format_write(" {} MP", [s[:]], buffer, start)
      Op_DP(s, o) => {
        let mut offset = start
        offset += @fmt.format_write(" {}", [s[:]], buffer, offset)
        offset += @fmt.Format::write(o, buffer, offset)
        offset += @fmt.format_write(" DP", [], buffer, offset)
        offset - start
      }
      Op_BMC(s) => @fmt.format_write(" {} BMC", [s[:]], buffer, start)
      Op_BDC(s, obj) => {
        let mut offset = start
        offset += @fmt.format_write(" {} ", [s[:]], buffer, offset)
        offset += @fmt.Format::write(obj, buffer, offset)
        offset += @fmt.format_write(" BDC", [], buffer, offset)
        offset - start
      }
      Op_EMC => @fmt.format_write(" EMC", [], buffer, start)
      Op_BX => @fmt.format_write(" Bx", [], buffer, start)
      Op_Unknown(_) => 0
      Op_Comment(s) => @fmt.format_write(" % {}\n", [s[:]], buffer, start)
      OP_EX => @fmt.format_write(" EX", [], buffer, start)
      Op_sc(fs) => {
        let mut offset = start
        for f in fs {
          offset += @fmt.format_write(" {}", [f], buffer, offset)
        }
        offset += @fmt.format_write(" sc", [], buffer, offset)
        offset - start
      }
    }
  } catch {
    _ => panic()
  }
}

///|
impl @fmt.Format for GraphicsOp with count(value : GraphicsOp) -> Int {
  let count = match value {
    Op_w(w) => @fmt.Format::count(w)
    Op_J(j) => @fmt.Format::count(j)
    Op_j(j) => @fmt.Format::count(j)
    Op_M(m) => @fmt.Format::count(m)
    Op_cm(t) =>
      @fmt.Format::count(t.a) +
      @fmt.Format::count(t.b) +
      @fmt.Format::count(t.c) +
      @fmt.Format::count(t.d) +
      @fmt.Format::count(t.e) +
      @fmt.Format::count(t.f)
    Op_BT => 0
    Op_ET => 0
    Op_Tf(k, s) => @fmt.Format::count(k) + @fmt.Format::count(s)
    Op_Tj(s) => @fmt.Format::count(s)
    Op_d(fl, y) => {
      let mut cnt = 0
      for f in fl {
        cnt += @fmt.Format::count(f)
      }
      cnt + @fmt.Format::count(y)
    }
    Op_ri(s) => @fmt.Format::count(s)
    Op_i(i) => @fmt.Format::count(i)
    Op_gs(s) => @fmt.Format::count(s)
    Op_q => 0
    Op_Q => 0
    Op_m(a, b) => @fmt.Format::count(a) + @fmt.Format::count(b)
    Op_l(a, b) => @fmt.Format::count(a) + @fmt.Format::count(b)
    Op_c(a, b, c, d, e, k) =>
      @fmt.Format::count(a) +
      @fmt.Format::count(b) +
      @fmt.Format::count(c) +
      @fmt.Format::count(d) +
      @fmt.Format::count(e) +
      @fmt.Format::count(k)
    Op_v(a, b, c, d) =>
      @fmt.Format::count(a) +
      @fmt.Format::count(b) +
      @fmt.Format::count(c) +
      @fmt.Format::count(d)
    Op_y(a, b, c, d) =>
      @fmt.Format::count(a) +
      @fmt.Format::count(b) +
      @fmt.Format::count(c) +
      @fmt.Format::count(d)
    Op_h => 0
    Op_re(a, b, c, d) =>
      @fmt.Format::count(a) +
      @fmt.Format::count(b) +
      @fmt.Format::count(c) +
      @fmt.Format::count(d)
    Op_S => 0
    Op_s => 0
    Op_f => 0
    Op_F => 0
    Op_f_star => 0
    Op_B => 0
    Op_B_star => 0
    Op_b => 0
    Op_b_star => 0
    Op_n => 0
    Op_W => 0
    Op_W_star => 0
    Op_Tc(c) => @fmt.Format::count(c)
    Op_Tw(w) => @fmt.Format::count(w)
    Op_Tz(z) => @fmt.Format::count(z)
    Op_TL(l) => @fmt.Format::count(l)
    Op_Tr(i) => @fmt.Format::count(i)
    Op_Ts(r) => @fmt.Format::count(r)
    Op_Td(k, k_) => @fmt.Format::count(k) + @fmt.Format::count(k_)
    Op_TD(k, k_) => @fmt.Format::count(k) + @fmt.Format::count(k_)
    Op_Tm(t) =>
      @fmt.Format::count(t.a) +
      @fmt.Format::count(t.b) +
      @fmt.Format::count(t.c) +
      @fmt.Format::count(t.d) +
      @fmt.Format::count(t.e) +
      @fmt.Format::count(t.f)
    Op_T_star => 0
    Op_TJ(obj) => 2 + @fmt.Format::count(obj)
    Op_single_quote(s) => @fmt.Format::count(s)
    Op_double_quote(k, k_, s) =>
      @fmt.Format::count(k) + @fmt.Format::count(k_) + @fmt.Format::count(s)
    Op_d0(k, k_) => @fmt.Format::count(k) + @fmt.Format::count(k_)
    Op_d1(a, b, c, d, e, k) =>
      @fmt.Format::count(a) +
      @fmt.Format::count(b) +
      @fmt.Format::count(c) +
      @fmt.Format::count(d) +
      @fmt.Format::count(e) +
      @fmt.Format::count(k)
    Op_CS(s) => @fmt.Format::count(s)
    Op_cs(s) => @fmt.Format::count(s)
    Op_SC(fs) => {
      let mut cnt = 0
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
    Op_SCN(fs) => {
      let mut cnt = 0
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
    Op_scn(fs) => {
      let mut cnt = 0
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
    Op_scnName(s, fs) => {
      let mut cnt = @fmt.Format::count(s)
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
    Op_SCNName(s, fs) => {
      let mut cnt = @fmt.Format::count(s)
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
    Op_G(k) => @fmt.Format::count(k)
    Op_g(k) => @fmt.Format::count(k)
    Op_RG(r, g, b) =>
      @fmt.Format::count(r) + @fmt.Format::count(g) + @fmt.Format::count(b)
    Op_rg(r, g, b) =>
      @fmt.Format::count(r) + @fmt.Format::count(g) + @fmt.Format::count(b)
    Op_K(c, m, y, k) =>
      @fmt.Format::count(c) +
      @fmt.Format::count(m) +
      @fmt.Format::count(y) +
      @fmt.Format::count(k)
    Op_k(c, m, y, k) =>
      @fmt.Format::count(c) +
      @fmt.Format::count(m) +
      @fmt.Format::count(y) +
      @fmt.Format::count(k)
    Op_sh(s) => @fmt.Format::count(s)
    Op_Do(s) => @fmt.Format::count(s)
    Op_MP(s) => @fmt.Format::count(s)
    Op_DP(s, o) => @fmt.Format::count(s) + @fmt.Format::count(o)
    Op_BMC(s) => @fmt.Format::count(s)
    Op_BDC(s, obj) => @fmt.Format::count(s) + @fmt.Format::count(obj)
    InlineImage(o, os, xs) =>
      @fmt.Format::count(o) +
      (match os {
        Some(o) => @fmt.Format::count(o)
        None => 0
      }) +
      xs.length()
    Op_EMC => 0
    Op_BX => 0
    OP_EX => 0
    Op_Unknown(s) => 0
    Op_Comment(s) => @fmt.Format::count(s)
    Op_sc(fs) => {
      let mut cnt = 0
      for f in fs {
        cnt += @fmt.Format::count(f)
      }
      cnt
    }
  }
  // 10 exceeds the actual required size.
  count + 10
}
