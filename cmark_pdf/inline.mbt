///|
/// 
/// This function currently flatten markdown style only select major style
/// 
/// 
pub fn Inline::from_cmark(inline : @cmark.Inline) -> Array[Inline] {
  // TODO: need refactor, in order to make code more clean.
  let result = []
  let _ = match inline {
    Text({ v: text, .. }) => result.push(Plain(text))
    Emphasis({ v: ilem, .. }) => {
      let text = loop ilem.inline {
        Text({ v: text, .. }) => text
        Emphasis({ v: ilem, .. }) => continue ilem.inline
        StrongEmphasis({ v: ilstem, .. }) => continue ilstem.inline
        _ => panic()
      }
      result.push(Emphasis(text))
    }
    StrongEmphasis({ v: ilstem, .. }) => {
      let text = loop ilstem.inline {
        Text({ v: text, .. }) => text
        Emphasis({ v: ilem, .. }) => continue ilem.inline
        StrongEmphasis({ v: ilstem, .. }) => continue ilstem.inline
        _ => panic()
      }
      result.push(StrongEmphasis(text))
    }
    Inlines({ v: inlines, .. }) => {
      let inlines = inlines.to_array()
      for inline in inlines {
        match inline {
          Text({ v: text, .. }) => result.push(Plain(text))
          Emphasis({ v: ilem, .. }) => {
            let text = loop ilem.inline {
              Text({ v: text, .. }) => text
              Emphasis({ v: ilem, .. }) => continue ilem.inline
              StrongEmphasis({ v: ilstem, .. }) => continue ilstem.inline
              _ => panic()
            }
            result.push(Emphasis(text))
          }
          StrongEmphasis({ v: ilstem, .. }) => {
            let text = loop ilstem.inline {
              Text({ v: text, .. }) => text
              Emphasis({ v: ilem, .. }) => continue ilem.inline
              StrongEmphasis({ v: ilstem, .. }) => continue ilstem.inline
              _ => panic()
            }
            result.push(StrongEmphasis(text))
          }
          _ => panic()
        }
      }
    }
    _ => panic()
  }
  result
}
