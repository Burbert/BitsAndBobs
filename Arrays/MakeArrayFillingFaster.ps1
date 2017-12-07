# normally you would probably declrare an array like this:
$Array = @()
# and than you would fill it with the += Operator within a loop 

1..50 | ForEach-Object {
    $Array += $_
}

# But this is not good, at least in large workloads.
# Why do you ask? Good question! Eevery time a vlaue is being added, the array will be emptied and rewritten with the additional entry.
# Imagine you would rewrite a page in a notebook to add a new note - nobody would do that.
# The solution? The Array object has an Add-Method that does exactly what we want, it just adds an entry at the end.

# But you have to decrlare the array as shown below:
[System.Collections.ArrayList]$Array = @()

# Filling the array

1..50 | ForEach-Object {
    $Array.Add($_) | Out-Null
}

# Why the Out-Null at the end? The Add-Method will return the index of the added entry and we don't want that - or maybe you do, as you like :)