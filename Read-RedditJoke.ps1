Function Read-Lines{
    <#
    .SYNOPSIS
    Speaks provided text via Windows speech synthesizer
    
    .DESCRIPTION
    Speaks provided text via Windows speech synthesizer.  Default voice is 'Microsoft Zira Desktop'.  No check for required assembly currently implimented.
    
    .PARAMETER lines
    Designated text to speak. Accepts array.

    .PARAMETER voice
    Specify voice to read text. Options are 'Microsoft Zira Desktop','Microsoft David Desktop' as they are installed by default
    #>
    param(
        [Parameter(Mandatory=$true)]
        $lines,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Microsoft Zira Desktop','Microsoft David Desktop')]
        $voice = 'Microsoft Zira Desktop'
    )

    #Add requires speech synthesizer assembly
    Add-Type -AssemblyName System.speech
    #Define new speek object
    $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
    #Define voice
    $speak.SelectVoice($voice)
    #Call assembly to read text
    foreach($line in $lines){
        $speak.Speak($line)
    }
}

Function Get-RedditPosts{
    <#
    .SYNOPSIS
    Retrieves posts from designated subreddit and category
    
    .DESCRIPTION
    Retrieves posts from designated subreddit and category
    
    .PARAMETER category
    Designate category for provided subreddit.  Available categories are HOT, TOP, BEST, NEW
    Default category is HOT

    .PARAMETER subreddit
    Designate subreddit to retrieve posts
    #>
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category = 'hot',
        [Parameter(Mandatory=$true)]
        [string]
        $subreddit
    )
    #Case seems to effect webrequest.  Set to lower case
    $category = $category.ToLower()
    #Web request to reddit expecting JSON format response
    $jsonresponse = Invoke-WebRequest -Uri reddit.com/r/$subreddit/$category/.json
    #Get posts in response
    $posts = ($jsonresponse.content | ConvertFrom-Json).data.children.data
    return $posts
} 

Function Get-RedditJokes{
    <#
    .SYNOPSIS
    Retrieves jokes from defined 'joke' subreddits

    .DESCRIPTION
    Retrieves jokes from defined 'joke' subreddits.  Expected format is joke setup in the title, and punchline in the body.
    
    .PARAMETER category
    Designate category for provided subreddit.  Available categories are HOT, TOP, BEST, NEW
    Default category is HOT

    .PARAMETER subreddit
    Designate subreddit to retrieve posts
    #>
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category='hot',
        [Parameter(Mandatory=$false)]
        [string]
        $subreddit='jokes'
    )
    Get-RedditPosts -subreddit $subreddit -category $category
    return $jokes
}

Function Find-ShortJoke{
    <#
    .SYNOPSIS
    Finds randdom joke of specified lenght from provided array
    .DESCRIPTION
    Finds randdom joke of specified lenght from provided array
    .PARAMETER jokes
    Array containing reddit joke posts
    .PARAMETER length
    Designate a maximum lenth for a joke.  This prevents walls of text from being sent to the Windows speech synthesizer.  No one wants to listen to all that.
    #>
    param(
        [Parameter(Mandatory=$true)]
        $jokes,
        [Parameter(Mandatory=$false)]
        $length = 30
    )
    #Define arrary to store jokes within the specified word count
    $shortJokes = @()
    #Iterate through provided jokes.  Add jokes within defined paramaters to array
    foreach($joke in $jokes){
        $titleWordCount = $joke.title | Measure-Object -Word | Select-Object -ExpandProperty Words
        $selftextWordCount = $joke.selftext | Measure-Object -Word | Select-Object -ExpandProperty Words
        if($titleWordCount + $selftextWordCount -le $length){
            $shortJokes += $joke
        }
    }
    #Return random joke in array
    return $(Get-Random $shortJokes)
}

Function Read-RedditJoke{
    <#
    .SYNOPSIS
    Main function.  Read a random joke from reddit
    
    .DESCRIPTION
    Main function.  Retrieves a random joke from a subreddit and utilizes the Windows speech synthesizer to audibly read joke.  Reads title and selftext of post
    No caching mechanism has been implimented so repeat jokes may occur.
    There is no content filter capability so jokes may be NSFW.  Use at your own risk.
    

    .PARAMETER category
    Designate category for provided subreddit.  Available categories are HOT, TOP, BEST, NEW
    Default category is HOT

    .PARAMETER subreddit
    Designate predefined subreddit to retrieve posts.  Random will pull from random joke related subreddit.  Limited set of subreddits are permitted to to formatting constraints.
    Many joke related subreddits are not text based, will need to impliment logic to exclude non text based posts.

    .PARAMETER wordLength
    Specify maximum number of words allowed in a post.  Combines total word count of setup and punchline.

    .PARAMETER noText
    Set to true to prevent lines from being written to the console

    #>
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category='top',
        [Parameter(Mandatory=$false)]
        [string]
        $subreddit='random',
        [Parameter(Mandatory=$false)]
        $wordLength = 30,
        [Parameter(Mandatory=$false)]
        [bool]$noText = $false
    )
    
    #Have not yet found a method that would allow me to define a list in a validate parameter set.  Want to have one spot to update available subreddits so I'll use a list and if statements to get desired outcome for now.
    #Define list of available subreddits
    $subredditList = @('jokes','dadjokes','oneliners','cleanjokes')
    #If random was provided, get random subreddit from list
    if($subreddit -eq 'random'){
        $subreddit = Get-Random $subredditList
    }else{
        #Evaluate if reddit is on available subreddit list
        if($subredditList -notcontains $subreddit){
            Write-Host "Subreddit not available"
            return
        }
    }
    

    #Retrieve list of jokes from reddit
    $jokes = Get-RedditJokes -category $category -subreddit $subreddit

    #Find a random joke within specified word count
    $joke = Find-ShortJoke $jokes -length $wordLength

    #No reddit joke found within the specified parameters
    if(!$joke){
        #Call main function again for another attempt.  May cause infinate loop.
        Write-Host "No joke found, trying again..." -ForegroundColor Yellow
        Read-RedditJoke -category $category -subreddit $subreddit -wordLength $wordLength
        return
    }

    #Write info to console unless otherwise indicated
    if(!$noText){
        Write-Host "Subreddit : $subreddit"
        Write-Host "Category : $category"
        Write-Host "Max Joke length : $wordLength"
        Write-Host "Joke Length : "  $($($joke.title | Measure-Object -Word | Select-Object -ExpandProperty Words) + $($joke.selftext | Measure-Object -Word | Select-Object -ExpandProperty Words)) "words" 
        Write-Host "Url : $($joke.url)"
        Write-Host "$($joke.title)"
    }

    #Audibly play the joke title
    Read-Lines $joke.title
    
    if(!$noText){
        Write-Host "$($joke.selftext)"
    }

    #Audibly play the joke punchline
    Read-Lines $joke.selftext
}

#Call main function
Read-RedditJoke