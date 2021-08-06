Function Say($lines){
    Add-Type -AssemblyName System.speech
    $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $speak.SelectVoice('Microsoft Zira Desktop')
    foreach($line in $lines){
        Write-Host "$line"
        $speak.Speak($line)
    }
}

Function Get-RedditPosts{
    param(
        [Parameter(Mandatory=$false)]
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
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category,
        [Parameter(Mandatory=$false)]
        [ValidateSet('jokes','dadjokes')]
        [string]
        $subreddit='jokes'
    )
    Get-RedditPosts -subreddit $subreddit -category $category
    return $jokes
}

Function Find-ShortJoke{
    param(
        [Parameter(Mandatory=$true)]
        $jokes,
        $length
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

Function SayRedditJoke{
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('hot','top','best','new')]
        [string]
        $category='top',
        [Parameter(Mandatory=$false)]
        [ValidateSet('jokes','dadjokes')]
        [string]
        $subreddit='jokes'
    )

    $wordLength = '30'
    $jokes = Get-RedditJokes -category $category -subreddit $subreddit
    $joke = Find-ShortJoke $jokes -length $wordLength
    if(!$joke){Write-Host "No joke found"}

    Write-Host "Subreddit : $subreddit"
    Write-Host "Category : $category"
    Write-Host "Max Joke length : $wordLength"
    Write-Host "Joke Length : "  $($($joke.title | Measure-Object -Word | Select-Object -ExpandProperty Words) + $($joke.selftext | Measure-Object -Word | Select-Object -ExpandProperty Words)) "words" 
    Write-Host "Url : $($joke.url)"
    Say $joke.title
    Say $joke.selftext
}

SayRedditJoke -category top -subreddit dadjokes