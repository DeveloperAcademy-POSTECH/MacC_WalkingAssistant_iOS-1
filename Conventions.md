# 이슈발급 -> 커밋 -> 이슈종료 지향
## Issue Convention
- Issue 의 title 시작을 tag로 시작한다

- PR를 올리기 전에 Issue를 생성하고 연결한다

- 작업에 대한 원인과 흐름등을 설정한다

- 버그 이슈일때는 버그의 재현방법을 자세히 기술한다

## Commit Convention
### Commit message structure

<br>

> type: Subject<br><br>
> body<br><br>
> footer

### Type
타입에는 작업 타입을 나타내는 태그를 적습니다.<br>
작업 타입에는 대략 다음과 같은 종류가 있습니다.
|*Type*|*Subject*|
|:---|:---|
|**[Feat]**|새로운 기능 추가|
|**[Add]**|새로운 뷰, 에셋, 파일, 데이터... 추가|
|**[Fix]**|버그 수정|
|**[Build]**|빌드 관련 파일 수정|
|**[Design]**|UI Design 변경|
|**[Docs]**|문서 (문서 추가, 수정, 삭제)|
|**[Style]**|스타일 (코드 형식, 세미콜론 추가: 비즈니스 로직에 변경 없는 경우)|
|**[Refactor]**|코드 리팩토링|
|**[Rename]**|파일명 또는 디렉토리명을 단순히 변경만 한 경우|
|**[Delete]**|파일 또는 디렉토리를 단순히 삭제만 한 경우|

예시) [Type] #이슈번호 커밋메세지 `git commit -m "[Feat] #12 로그인 기능 추가"`

### Issue



## PR Convention
    1. Motivation
    2. Key Changes
    3. To Reviewers
