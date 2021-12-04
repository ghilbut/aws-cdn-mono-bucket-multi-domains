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

## 컨셉

하나의 `CloudFront`와 `S3 Bucket`만으로 여러 도메인을 `HTTPS`로 서비스 할 수 있습니다. 이 아이디어는 프론트엔드 배포 환경 관리를 좀 더 단순하게 만들어 줍니다. 또한, 필요한 `CloudFront`와 `Certification Manager`를 하나로 줄여주어 운영 비용을 절약할 수 있습니다. 만약, 와일드카드 도메인을 사용한다면 추가적인 설정의 변경 없이 S3에 파일을 배포하는 것만으로 도메인을 계속 확장할 수 있습니다.

이 아이디어는 프론트엔드 개발 환경을 개선하는 것에서 시작되었습니다. 각각의 브랜치들과 개발자들이 담당하는 Feature들에 대하여 디자이너 및 이해관계자들과 동작하는 대상을 기준으로 대화하는 것이 업무에 효과적이라고 생각했습니다. 그러나 프론트엔드 개발자들은 백엔드 개발자들보다 상대적으로 데브옵스와 멀리 있습니다. 때문에 배포에 대한 개념을 감추면서 유연한 배포 환경을 제공하는 것에 대하여 고민했습니다.

## 요구사항

CDN은 다음과 같은 두 가지 형태의 프론트엔드 환경을 지원해야 합니다.

* Static Files
  * 호출되는 도메인과 경로에 있는 파일을 서비스 합니다.
  * 파일이 없다면 `404`를 반환합니다.
* SPA(Single page application)
  * 호출되는 도메인과 경로에 있는 파일을 서비스 합니다.
  * 파일이 없다면 SPA의 `index.html`을 서비스하여 동적 route 페이지를 서비스 합니다.
  * SPA의 동적 페이지 경로에 해당하지 않는다면, SPA가 `404` 페이지를 서비스 합니다.

## 개념



## 성능

많은 경우에 성능과 편리함은 Trade off 관계를 갖습니다. 이 구성에서는 `Lambda@Edge`가 성능의 가장 큰 변수가 되는 지점이라고 생각합니다. 지금 구성된 `Lambda@Edge`에서는 성능과 관련하여 다음과 같은 결정들을 내렸습니다.



```python
{ % highlight python linenos % }

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

{ % endhighlight % }
```
