local highlight = {}

back_color = {37/255, 35/255, 35/255}
text_color = {249/255, 245/255, 215/255}
kw_color = {251/255, 73/255, 52/255}
str_color = {142/255, 192/255, 124/255}
operator_color = {250/255, 230/255, 120/255}
comment_color = {146/255, 131/255, 116/255}
fn_color = {69/255, 133/255, 136/255}
attr_color = {215/255, 153/255, 33/255}
number_color = {211/255, 134/255, 155/255}

separators = '[%s%+%-=%*/:;%%,%.%(%)%[%]{}\'\"]'

local function kw_rule(text,i,j)
  return (i==1 or text:sub(i-1,i-1):find(separators)) and text:sub(j+1,j+1):find(separators)
end

local function self_rule(text,i,j)
  return (i==1 or text:sub(i-1,i-1):find(separators)) and text:sub(j+1,j+1):find('[%s%.:]')
end

local function pass(_,_,_) return true end

local function fn_rule(text,i,j)
  return text:sub(i-1,i-1):find(':') or text:sub(j+1,j+1):find('%(')
end

local function attr_rule(text,i,j)
  return text:sub(i-1,i-1):find('%.') and not 
         text:sub(i-1,i-1):find(':')  and not 
         text:sub(j+1,j+1):find('%(') and not
         text:sub(i-2,i-2):find('%.')
end

local function number_rule(text,i,j)
  return text:sub(i-1,i-1):find(separators) and
         text:sub(j+1,j+1):find(separators)
end

highlight.lua = {
  { to_hl = 'local',    rule = kw_rule, color = kw_color },
  { to_hl = 'return',   rule = kw_rule, color = kw_color },
  { to_hl = 'end',      rule = kw_rule, color = kw_color },
  { to_hl = 'do',       rule = kw_rule, color = kw_color },
  { to_hl = 'for',      rule = kw_rule, color = kw_color },
  { to_hl = 'while',    rule = kw_rule, color = kw_color },
  { to_hl = 'repeat',   rule = kw_rule, color = kw_color },
  { to_hl = 'until',    rule = kw_rule, color = kw_color },
  { to_hl = 'nil',      rule = kw_rule, color = kw_color },
  { to_hl = 'true',     rule = kw_rule, color = kw_color },
  { to_hl = 'false',    rule = kw_rule, color = kw_color },
  { to_hl = 'if',       rule = kw_rule, color = kw_color },
  { to_hl = 'in',       rule = kw_rule, color = kw_color },
  { to_hl = 'then',     rule = kw_rule, color = kw_color },
  { to_hl = 'else',     rule = kw_rule, color = kw_color },
  { to_hl = 'elseif',   rule = kw_rule, color = kw_color },
  { to_hl = 'function', rule = kw_rule, color = kw_color },
  { to_hl = 'self',     rule = self_rule, color = kw_color },
  { to_hl = 'and',      rule = kw_rule, color = kw_color },
  { to_hl = 'not',      rule = kw_rule, color = kw_color },
  { to_hl = 'or',       rule = kw_rule, color = kw_color },
  { to_hl = 'break',    rule = kw_rule, color = kw_color },
  { to_hl = '\'.-[\n\']',  rule = pass, color = str_color},
  { to_hl = '\".-[\n\"]',  rule = pass, color = str_color},
  { to_hl = '%-%-.-\n',     rule = pass, color = comment_color},
  { to_hl = '%-%-%[%[.-]]', rule = pass, color = comment_color},
  { to_hl = '[%-%+=/#~<>%*]', rule = pass, color = operator_color},
  { to_hl = '%.%.',           rule = pass, color = operator_color},
  { to_hl = 'require',        rule = kw_rule, color = operator_color},
  { to_hl = 'io',             rule = kw_rule, color = operator_color},
  { to_hl = 'string',         rule = kw_rule, color = operator_color},
  { to_hl = 'table',          rule = kw_rule, color = operator_color},
  { to_hl = 'os',             rule = kw_rule, color = operator_color},
  { to_hl = 'math',           rule = kw_rule, color = operator_color},
  { to_hl = '%a[%a%d_]*', rule = attr_rule, color = attr_color},
  { to_hl = '%a[%a%d_]*', rule = fn_rule,   color = fn_color},
  { to_hl = '%d+',     rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+', rule = number_rule, color = number_color},
  { to_hl = '%d+e%-?%d+', rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+e%-?%d+', rule = number_rule, color = number_color},
}

highlight.c = {
  { to_hl = 'auto',     rule = kw_rule, color = kw_color },
  { to_hl = 'return',   rule = kw_rule, color = kw_color },
  { to_hl = 'case',     rule = kw_rule, color = kw_color },
  { to_hl = 'char',     rule = kw_rule, color = kw_color },
  { to_hl = 'for',      rule = kw_rule, color = kw_color },
  { to_hl = 'while',    rule = kw_rule, color = kw_color },
  { to_hl = 'const',    rule = kw_rule, color = kw_color },
  { to_hl = 'continue', rule = kw_rule, color = kw_color },
  { to_hl = 'do',       rule = kw_rule, color = kw_color },
  { to_hl = 'true',     rule = kw_rule, color = kw_color },
  { to_hl = 'false',    rule = kw_rule, color = kw_color },
  { to_hl = 'if',       rule = kw_rule, color = kw_color },
  { to_hl = 'default',  rule = kw_rule, color = kw_color },
  { to_hl = 'double',   rule = kw_rule, color = kw_color },
  { to_hl = 'else',     rule = kw_rule, color = kw_color },
  { to_hl = 'enum',     rule = kw_rule, color = kw_color },
  { to_hl = 'extern',   rule = kw_rule, color = kw_color },
  { to_hl = 'float',    rule = self_rule, color = kw_color },
  { to_hl = 'goto',     rule = kw_rule, color = kw_color },
  { to_hl = 'inline',   rule = kw_rule, color = kw_color },
  { to_hl = 'int',      rule = kw_rule, color = kw_color },
  { to_hl = 'break',    rule = kw_rule, color = kw_color },
  { to_hl = 'long',     rule = kw_rule, color = kw_color },
  { to_hl = 'register', rule = kw_rule, color = kw_color },
  { to_hl = 'restrict', rule = kw_rule, color = kw_color },
  { to_hl = 'short',    rule = kw_rule, color = kw_color },
  { to_hl = 'signed',   rule = kw_rule, color = kw_color },
  { to_hl = 'sizeof',   rule = kw_rule, color = kw_color },
  { to_hl = 'static',   rule = kw_rule, color = kw_color },
  { to_hl = 'struct',   rule = kw_rule, color = kw_color },
  { to_hl = 'switch',   rule = kw_rule, color = kw_color },
  { to_hl = 'typedef',  rule = kw_rule, color = kw_color },
  { to_hl = 'union',    rule = kw_rule, color = kw_color },
  { to_hl = 'unsigned', rule = kw_rule, color = kw_color },
  { to_hl = 'void',     rule = kw_rule, color = kw_color },
  { to_hl = 'bool',     rule = kw_rule, color = kw_color },
  { to_hl = 'volatile', rule = kw_rule, color = kw_color },
  { to_hl = '#include', rule = kw_rule, color = kw_color },
  { to_hl = '#define',  rule = kw_rule, color = kw_color },
  { to_hl = '#if',      rule = kw_rule, color = kw_color },
  { to_hl = '#else',    rule = kw_rule, color = kw_color },
  { to_hl = '#undef',   rule = kw_rule, color = kw_color },
  { to_hl = '#ifdef',   rule = kw_rule, color = kw_color },
  { to_hl = '#endif',   rule = kw_rule, color = kw_color },
  { to_hl = '#line',    rule = kw_rule, color = kw_color },
  { to_hl = '#error',   rule = kw_rule, color = kw_color },
  { to_hl = '#pragma',  rule = kw_rule, color = kw_color },
  { to_hl = '#ifndef',  rule = kw_rule, color = kw_color },
  { to_hl = '%a[%a%d_]*_t', rule = kw_rule, color = kw_color },
  { to_hl = '\'..?\'',  rule = pass, color = str_color},
  { to_hl = '\".-[\n\"]',  rule = pass, color = str_color},
  { to_hl = '<%a[%a%d_]-%.h>',rule = pass, color = comment_color},
  { to_hl = '//.-\n',        rule = pass, color = comment_color},
  { to_hl = '/%*.-%*/',      rule = pass, color = comment_color},
  { to_hl = '[%-%+=/&<>%*]', rule = pass, color = operator_color},
  { to_hl = '&&',        rule = kw_rule, color = operator_color},
  { to_hl = '||',        rule = kw_rule, color = operator_color},
  { to_hl = '<<',        rule = kw_rule, color = operator_color},
  { to_hl = '>>',        rule = kw_rule, color = operator_color},
  { to_hl = '%a[%a%d_]*', rule = attr_rule, color = attr_color},
  { to_hl = '%a[%a%d_]*', rule = fn_rule,   color = fn_color},
  { to_hl = '%d+',            rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+',        rule = number_rule, color = number_color},
  { to_hl = '%d+e%-?%d+',     rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+e%-?%d+', rule = number_rule, color = number_color},
}

highlight.h = highlight.c
highlight.cpp = highlight.c
highlight.hpp = highlight.c

return highlight
