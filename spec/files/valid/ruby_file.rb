class SomeClass
  def a_method
    'Single Quoted {first} {second}'[:single_quoted, 1, 2]

    'Single
Quoted'[:single_quoted_newline]

    'Single with \' quotes'[:single_with_quotes]
    'Single with \' quotes'[:single_with_quotes]
    
    :single_with_quotes.l
  end
  
  def another_method
    "double QUOTED"[:double_quoted]
    hash[:double_quoted] # Should not get picked up

    "double
with newline"[:double_quoted_newline]

    "double With \"
quotes"[:double_with_quotes]
  end
end