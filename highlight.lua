local highlight = {}

back_color = {29/255, 32/255, 33/255}
text_color = {249/255, 245/255, 215/255}
kw_color = {251/255, 73/255, 52/255}
str_color = {142/255, 192/255, 124/255}
operator_color = {235/255, 219/255, 78/255}
comment_color = {146/255, 131/255, 116/255}
fn_color = {69/255, 133/255, 136/255}
attr_color = {215/255, 153/255, 33/255}
number_color = {211/255, 134/255, 155/255}

local function kw_rule(text,i,j)
  return (i==1 or text:sub(i-1,i-1):find('%A')) and text:sub(j+1,j+1):find('%s')
end

local function self_rule(text,i,j)
  return (i==1 or text:sub(i-1,i-1):find('%A')) and text:sub(j+1,j+1):find('[%s%.:]')
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
  return text:sub(i-1,i-1):find('[%s%+%-%*/%(%)%[%]{},]?') and
         text:sub(j+1,j+1):find('[%s%+%-%*/%(%)%[%]{},]?')
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
  { to_hl = 'then',     rule = kw_rule, color = kw_color },
  { to_hl = 'else',     rule = kw_rule, color = kw_color },
  { to_hl = 'elseif',   rule = kw_rule, color = kw_color },
  { to_hl = 'function', rule = kw_rule, color = kw_color },
  { to_hl = 'self',     rule = self_rule, color = kw_color },
  { to_hl = 'and',      rule = kw_rule, color = kw_color },
  { to_hl = 'not',      rule = kw_rule, color = kw_color },
  { to_hl = 'or',       rule = kw_rule, color = kw_color },
  { to_hl = '\'.-[\n\']',  rule = pass, color = str_color},
  { to_hl = '\".-[\n\"]',  rule = pass, color = str_color},
  { to_hl = '%-%-.-\n',     rule = pass, color = comment_color},
  { to_hl = '%-%-%[%[.-]]', rule = pass, color = comment_color},
  { to_hl = '[%-%+=/#~<>%*]', rule = pass, color = operator_color},
  { to_hl = '%.%.', rule = pass, color = operator_color},
  { to_hl = '%a[%a%d_]*', rule = attr_rule, color = attr_color},
  { to_hl = '%a[%a%d_]*', rule = fn_rule,   color = fn_color},
  { to_hl = '%d+',     rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+', rule = number_rule, color = number_color},
  { to_hl = '%d+e%-?%d+', rule = number_rule, color = number_color},
  { to_hl = '%d+.%d+e%-?%d+', rule = number_rule, color = number_color},
}

return highlight


