# aws-cdn-mono-bucket-multi-domains

```text
┬ .github
│  └ workflows  ## github actions for spa-examples
│
├ spa-examples
│  └ vue.js
│     ├ ev1   ## {host}.ghilbut.com/
│     ├ ev1x  ## {host}.ghilbut.com/x
│     └ ev1y  ## {host}.ghilbut.com/y
│ 
└ terraform
   ├ ghilbut.com  ## ghilbut.com and ghilbut.net preview environment
   └ module       ## terraform module for CDN environment
```

# CDN with Mono S3 Bucket

## 1. 컨셉

하나의 `CloudFront`와 `S3 Bucket`만으로 여러 도메인을 `HTTPS`로 서비스 할 수 있습니다. 이 아이디어는 프론트엔드 배포 환경 관리를 좀 더 단순하게 만들어 줍니다. 또한, 필요한 `CloudFront`와 `Certification Manager`를 하나로 줄여주어 운영 비용을 절약할 수 있습니다. 만약, 와일드카드 도메인을 사용한다면 추가적인 설정의 변경 없이 `S3`에 파일을 배포하는 것만으로 도메인을 계속 확장할 수 있습니다.

이 아이디어는 프론트엔드 개발 환경을 개선하는 것에서 시작되었습니다. 각각의 브랜치들과 개발자들이 담당하는 Feature들에 대하여 디자이너 및 이해관계자들과 동작하는 대상을 기준으로 대화하는 것이 업무에 효과적이라고 생각했습니다. 그러나 프론트엔드 개발자들은 백엔드 개발자들보다 상대적으로 데브옵스와 멀리 있습니다. 때문에 배포에 대한 개념을 감추면서 유연한 배포 환경을 제공하는 것에 대하여 고민했습니다.

## 2. 요구사항

CDN은 다음과 같은 두 가지 형태의 프론트엔드 환경을 지원해야 합니다.

* Static Files
  * 호출되는 도메인과 경로에 있는 파일을 서비스합니다.
  * 파일이 없다면 `404`를 반환합니다.


* SPA(Single page application)
  * 호출되는 도메인과 경로에 있는 파일을 서비스합니다.
  * 파일이 없다면 SPA의 `index.html`을 서비스하여 동적 route 페이지를 서비스합니다.
  * SPA의 동적 페이지 경로에 해당하지 않는다면, SPA가 `404` 페이지를 서비스합니다.

## 3. 개념

* `CDN`은 `GET`, `HEAD`, `OPTION` 요청들에 대응합니다. `CloudFront`는 `Global Edge`들에 해당 요청들의 응답을 캐싱합니다.
* URL에서 파일과 대응하는 요소는 `host` 이름과 `path` 입니다.
* `s3`에 파일들을 `host` 도메인으로 시작하는 `key`로 저장합니다.
* 리퀘스트가 `cloudfront`에 요청되면, `viewer-request` 이벤트에서 `lambda`를 호출합니다.
* `lambda`에서는 리퀘스트의 `host`와 `path`를 조합하여 `s3`에 대응하는 `key`를 만듭니다.
* `s3`에 해당 `key`가 존재하는지 확인하고 있다면 리퀘스트의 `uri`를 `key`로 치환합니다. 브라우저에는 `s3`의 `{host}/{path}`로 정의된 `key`에 대응하는 파일이 전달됩니다.
* `s3`에 해당 `key`가 없다면 부모 경로에 `index.html` 파일이 있는지 확인하여 있다면 해당 파일 경로를 `uri`에 치환합니다. 브라우저에는 SPA의 `index.html`이 전달됩니다. 브라우저에 요청된 경로를 렌더링 하는 것은 SPA의 `router` 정의에 따라 렌더링 됩니다.
* 만약, `index.html` 파일도 없다면 `uri`를 조작하지 않습니다. 모든 파일의 `key`들은 `host`로 시작되기 때문에 `uri` 값을 조작하지 않으면 `cloudfront`에 정의된 `404` 페이지가 전달됩니다.
* 최초 요청의 경우 `s3` 탐색에 의한 시간 지연이 있습니다. 그러나 `cloudfront`의 캐싱 시간이 0보다 크다면 동일한 파일의 요청에 대해서 캐싱된 컨텐츠를 즉각적으로 서비스합니다. 

## 4. 사용방법

CDN 구성은 [Terraform](https://www.terraform.io/)으로 제공됩니다.

[ghilbut.com 샘플](./terraform/ghilbut.com/main.tf#L21)을 확인하세요.

## 5. 성능

### 이상적인 상태

많은 경우에 성능과 편리함은 Trade off 관계를 갖습니다. 이 구성에서는 `Lambda@Edge`가 성능의 가장 큰 변수가 되는 지점이라고 생각합니다. 지금 구성된 `Lambda@Edge`에서는 성능과 관련하여 다음과 같은 결정들을 내렸습니다.

기본적인 브라우저 요청은 루트 페이지의 `index.html`을 생략하는 케이스가 아니라면 `html`, `css`, `js` 등의 파일들에 대하여 정확한 파일 경로를 지정하여 요청합니다. 따라서 `key` 값에 대응하는 파일을 제일 처음 탐색하는 것은 효과적인 결정입니다.

요청하는 위치에 `key`가 없을 경우, 부모 `path`의 어딘가에 `index.html` 파일이 있는지 탐색합니다. 이때, `host`로 시작하는 모든 `key`들을 받아와서 리스트에 `index.html`이 존재하는지 확인합니다. 이는 코드 내에서의 데이터 탐색이 네트워크에 접근하는 비용보다 저렴하기 때문에 `path`의 `parent`를 재귀로 탐색하여 `s3`에 여러번 네트워크로 API를 호출하는 것보다 낫다고 판단하였습니다. 실제로 간단한 테스트에서 5~6단계의 깊이를 갖는 `path`에 대한 SPA의 `index.html` 응답 시간이 평균 50% 정도 더 빠른 것을 확인하였습니다.

따라서 브라우저에서 페이지를 여는 최초의 `index.html` 탐색 시간을 제외하면 O(1) 탐색을 기대합니다.

```python
def find_key(host, path):
    base = os.path.join(host, path)

    try:
        s3.head_object(Bucket=bucket_name, Key=base)
        return base
    except ClientError:
        pass

    max_keys = 1000
    objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=max_keys, Prefix=host)
    if objects['KeyCount'] == 0:
        return None
    targets = [ obj['Key'] for obj in objects['Contents'] if obj['Key'].endswith('index.html') ]

    while objects['KeyCount'] == max_keys:
        last = objects['Contents'][-1]['Key']
        objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=max_keys, Prefix=host, StartAfter=last)
        if objects['KeyCount'] == 0:
            break
        targets.extend([ obj['Key'] for obj in objects['Contents'] if obj['Key'].endswith('index.html') ])

    targets.sort(key=lambda x: len(x.split('/')), reverse=True)
    for target in targets:
        if base.startswith(os.path.dirname(target)):
            return target

    return None
```

### 현실적인 문제

만약, 유효하지 않은 깊은 뎁스를 갖는 `path`를 지속적으로 호출한다면 클라이언트 측의 응답시간은 매우 느릴 것입니다. 또한, 대상 `host`에 1000개를 초과하는 파일들이 있다면 그 성능은 더욱 나빠집니다. 그러나 `cache`가 활성화 되어 있을 경우 같은 `path`의 호출에 대해서는 `lambda@edge`를 호출하지 않고 `cache` 된 응답을 돌려줍니다.

`cloudfront`와 연동하는 `lambda@edge`는 `lambda`와 과금 기준이 다릅니다. `lambda@edge`는 호출 횟수와 메모리 사용량을 기준으로 과금합니다. 다만, 앞서 기술한 바와 같이 `cache`가 활성화 될 경우 `lambda@edge`의 호출 횟수가 감소하기 때문에 가파른 비용 추가는 없을 것으로 예상합니다. 자세한 비용은 [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/) 페이지를 통해 확인할 수 있습니다. 

따라서 이와 같은 구성을 하였을 때, `DDoS` 공격에 대하여 기본적인 `CDN` 구성 대비 추가적인 성능 저하나 비용 증가를 걱정할 필요는 없습니다.


## 6. 다음 목표

Global Edge 캐싱이 필요할 경우 `CloudFront`는 좋은 선택입니다. 그러나 만약 캐싱을 하지 않는 내부의 개발환경을 구성해야 한다면, `CloudFront`는 너무 비싸며 망분리 환경에 대응하기 힘듭니다. 이를 위해서는 `CloudFront` + `Lambda@Edge`의 역할과 동일한 기능을 수행하는 서비스 서버가 필요할 수 있습니다. 이러한 역할을 수행하는 서버를 개발합니다.

---

# CI/CD with Github Actions

* **Example: [.github/workflows/ghilbut-ev1-preview.yml](./.github/workflows/ghilbut-ev1-preview.yml)**

우리는 제품을 개발하는 과정에서 각각의 기능들에 대하여 PO/BO 및 디자이너들과 개발 과정을 직접 눈으로 확인하면서 점진적인 수정을 해야 할 때가 있습니다. 대부분의 경우 한자리에 모여 개발자의 랩탑(localhost)에서 구동되는 화면을 보면서 의견을 교환합니다. 이러한 방법은 PO/BO와 디자이너들이 현재의 작업 내용에 대하여 충분히 검토할 수 있는 여유를 제공하지 못합니다. 따라서 개별 feature 브랜치에 대해서도 온라인에 게시되는 Preview 환경이 필요할 수 있습니다. 이 저장소는 이와 같은 환경을 지원하는 Github Actions 샘플을 포함하고 있습니다.

지금 소개하는 내용은 `CDN with Mono S3 Bucket`의 특성을 이용하는 것이므로 원리만 동일하다면 CI/CD에 꼭 Github Actions를 사용할 필요는 없습니다. 그러나, 반드시 S3 Bucket에 와일드카드 도메인을 연결해야 합니다.

## Process

아래 CI/CD 절차는 [Vercel](https://vercel.com/)을 대체하기 위하여 구성되었습니다. 

### Step 1. Preview 환경의 자동 생성 및 업데이트

Push(`push`) 이벤트에 반응합니다.

새로운 리모트 브랜치가 생성되거나 기존 브랜치에 커밋들이 푸시되면, 리모트 브랜치의 Ref값을 4자리 해시값으로 변환하여 Unique한 호스트 이름을 결정합니다. S3에 해당 호스트 이름을 Prefix로하여 파일들을 업로드 합니다. 업로드가 완료되면 브라우저에서 해당 호스트 주소로 접근하여 빌드 결과물들을 확인할 수 있습니다.

위의 방법은 하나의 예시일 뿐 Unique 호스트 이름을 결정할 수 있는 어떤 방법도 같은 효과를 기대할 수 있습니다. S3에 와일드카드 도메인으로 연결된 유효한 호스트 이름을 결정하여 업로드하세요.

현재는 이 스텝에서는 Github Actions의 console log들을 보아야 브랜치에 대응하는 Preview 주소를 알 수 있습니다. 만약, Github Actions의 다양한 플러그인들을 이용한다면 Slack을 포함한 여러 협업 도구들의 대화 채널에 Preview 주소를 알릴 수 있을 것입니다.

### Step 2. Preview URL을 PR Comment로 알림

PR(`pull_request`)이 오픈(`opened`)되었을 때 반응합니다.

해당 브랜치에 대하여 PR을 오픈하면 Preview URL을 PR의 Comment에 자동으로 추가합니다.

PR은 언제나 두 브랜치 사이에 차이점이 있어야만 만들 수 있으므로 PR을 만드는 시점에는 반드시 Preview 환경이 존재할 것으로 기대합니다. 다만, Step1의 첫 빌드가 완전히 끝나지 않거나 빌드가 실패한 상태에서 PR을 만든다면 Preview 환경이 존재하지 않을 수 있습니다. 그럴 경우 Comment에는 Preview 환경이 존재하지 않는다는 메세지를 남길 것입니다.

이는 Example 일 뿐이므로 정책은 자유롭게 변경할 수 있습니다. 방법에 따라 Github Issue에 Comment를 남기거나 Jira Tiket에 연동하는 방법도 생각해 볼 수 있을 것입니다.

### Step 3. Preview 환경의 자동 삭제

브랜치를 삭제한다면, 자동으로 S3에서 Preview 환경을 제거합니다.

## 확장 및 변형

이 저장소에서 Github Actions를 이용해 소개하는 CI/CD는 예시일 뿐입니다. S3에 호스트 이름을 Prefix로 지정하여 파일을 업로드 할 수만 있다면 어떤 향태로도 응용 및 확장이 가능합니다.