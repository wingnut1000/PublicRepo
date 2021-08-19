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
    $category = $category.ToLower()
    $jsonresponse = Invoke-WebRequest -Uri reddit.com/r/$subreddit/$category/.json
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
    Designate subreddit to retrieve posts  Available subreddits are JOKES, DADJOKES
    #>
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category='hot',
        [Parameter(Mandatory=$false)]
        [ValidateSet('jokes','dadjokes')]
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
    $shortJokes = @()
    foreach($joke in $jokes){
        $titleWordCount = $joke.title | Measure-Object -Word | Select-Object -ExpandProperty Words
        $selftextWordCount = $joke.selftext | Measure-Object -Word | Select-Object -ExpandProperty Words
        if($titleWordCount + $selftextWordCount -le $length){
            $shortJokes += $joke
        }
    }
    return $(Get-Random $shortJokes)
}

Function Read-RedditJoke{
    <#
    .SYNOPSIS
    Main function.  Read a random joke from reddit
    
    .DESCRIPTION
    Main function.  Retrieves a random joke from a subreddit and utilizes the Windows speech synthesizer to audibly read joke.  No caching mechanism has been implimented so repeat jokes may occur.
    There is no content filter capability so jokes may be NSFW.  Use at your own risk.
    

    .PARAMETER category
    Designate category for provided subreddit.  Available categories are HOT, TOP, BEST, NEW
    Default category is HOT

    .PARAMETER subreddit
    Designate subreddit to retrieve posts  Available subreddits are JOKES, DADJOKES

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
        [ValidateSet('jokes','dadjokes')]
        [string]
        $subreddit='jokes',
        [Parameter(Mandatory=$false)]
        $wordLength = 30,
        [Parameter(Mandatory=$false)]
        [bool]$noText = $false
    )

    #Retrieve list of jokes from reddit
    $jokes = Get-RedditJokes -category $category -subreddit $subreddit

    #Find a random joke within specified word count
    $joke = Find-ShortJoke $jokes -length $wordLength

    #No reddit joke found within the specified parameters
    if(!$joke){
        Write-Host "No joke found" -ForegroundColor RED
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
Read-RedditJoke -category top -subreddit dadjokes