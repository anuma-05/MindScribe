;; MindScribe: Decentralized Reflection Journal
;; A secure platform for storing and sharing personal reflections

;; Constants
(define-constant contract-admin tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-reflection (err u101))
(define-constant err-invalid-date (err u102))
(define-constant err-reflection-not-found (err u103))
(define-constant err-category-full (err u104))
(define-constant err-invalid-category (err u105))
(define-constant err-invalid-author (err u106))
(define-constant err-not-in-shared-pool (err u107))
(define-constant err-already-revealed (err u108))

;; Data Types
(define-map reflections
    { reflection-id: uint, author: principal }
    {
        text: (string-utf8 2048),
        created-at: uint,
        reveal-time: uint,
        is-hidden: bool,
        is-unnamed: bool,
        categories: (list 10 (string-utf8 32))
    }
)

;; Map for unnamed reflection pool
(define-map shared-pool
    uint  ;; reflection-id
    {
        author: principal,
        is-revealed: bool,
        reveal-block: uint
    }
)

(define-map reflection-counts principal uint)
(define-map category-index { category: (string-utf8 32) } (list 50 { reflection-id: uint, author: principal }))
(define-data-var shared-pool-counter uint u0)

;; Private Functions
(define-private (is-author (reflection-id uint))
    (match (map-get? reflections {reflection-id: reflection-id, author: tx-sender})
        entry true
        false)
)

(define-private (get-reflection-count-internal (user principal))
    (default-to u0 (map-get? reflection-counts user))
)

(define-private (validate-category (category (string-utf8 32)))
    (and (> (len category) u0) (<= (len category) u32))
)

(define-private (validate-category-list (category (string-utf8 32)) (valid bool))
    (and valid (validate-category category))
)

(define-private (validate-categories (categories (list 10 (string-utf8 32))))
    (and 
        (<= (len categories) u10)
        (fold validate-category-list categories true)
    )
)

(define-private (validate-author (author principal))
    (is-some (map-get? reflection-counts author))
)

(define-private (validate-flag (value bool))
    true
)

;; Generate reveal time for unnamed reflections
(define-private (generate-reveal-time)
    (let (
        (current-block block-height)
        (random-blocks (mod (var-get shared-pool-counter) u144))
    )
        (+ current-block (+ u72 random-blocks))
    )
)

;; Public Functions
(define-public (add-reflection (text (string-utf8 2048)) 
                             (reveal-time uint) 
                             (is-hidden bool)
                             (is-unnamed bool)
                             (categories (list 10 (string-utf8 32))))
    (let (
        (reflection-id (get-reflection-count-internal tx-sender))
        (validated-hidden (validate-flag is-hidden))
        (validated-unnamed (validate-flag is-unnamed))
    )
        (begin
            (asserts! (> (len text) u0) err-invalid-reflection)
            (asserts! (>= reveal-time block-height) err-invalid-date)
            (asserts! (validate-categories categories) err-invalid-category)
            (asserts! validated-hidden err-unauthorized)
            (asserts! validated-unnamed err-unauthorized)
            
            (map-set reflections
                { reflection-id: reflection-id, author: tx-sender }
                {
                    text: text,
                    created-at: block-height,
                    reveal-time: reveal-time,
                    is-hidden: is-hidden,
                    is-unnamed: is-unnamed,
                    categories: categories
                }
            )
            
            (map-set reflection-counts 
                tx-sender 
                (+ reflection-id u1))
            
            (if is-unnamed
                (begin
                    (map-set shared-pool
                        reflection-id
                        {
                            author: tx-sender,
                            is-revealed: false,
                            reveal-block: (generate-reveal-time)
                        }
                    )
                    (var-set shared-pool-counter (+ (var-get shared-pool-counter) u1))
                    (ok reflection-id)
                )
                (ok reflection-id)
            )
        )
    )
)

(define-public (read-reflection (reflection-id uint) (author principal))
    (let (
        (entry (unwrap! (map-get? reflections {reflection-id: reflection-id, author: author}) 
                         err-reflection-not-found))
        (shared-entry (map-get? shared-pool reflection-id))
    )
        (begin
            (asserts! (or
                (is-eq tx-sender author)
                (and
                    (not (get is-hidden entry))
                    (or
                        (>= block-height (get reveal-time entry))
                        (and
                            (is-some shared-entry)
                            (get is-revealed (unwrap! shared-entry err-not-in-shared-pool))
                        )
                    )
                )
            ) err-unauthorized)
            
            (ok {
                text: (get text entry),
                created-at: (get created-at entry),
                categories: (get categories entry),
                unnamed: (get is-unnamed entry)
            })
        )
    )
)

(define-public (update-visibility (reflection-id uint) 
                                (is-hidden bool)
                                (is-unnamed bool))
    (let ((entry (unwrap! (map-get? reflections 
                                   {reflection-id: reflection-id, author: tx-sender})
                         err-reflection-not-found)))
        (begin
            (asserts! (is-author reflection-id) err-unauthorized)
            (asserts! (validate-flag is-hidden) err-unauthorized)
            (asserts! (validate-flag is-unnamed) err-unauthorized)
            
            (map-set reflections
                { reflection-id: reflection-id, author: tx-sender }
                (merge entry {
                    is-hidden: is-hidden,
                    is-unnamed: is-unnamed
                })
            )
            (ok true)
        )
    )
)

(define-public (check-shared-reflection-status (reflection-id uint))
    (let ((entry (unwrap! (map-get? shared-pool reflection-id) err-not-in-shared-pool)))
        (begin
            (if (and
                    (not (get is-revealed entry))
                    (>= block-height (get reveal-block entry))
                )
                (begin
                    (map-set shared-pool
                        reflection-id
                        (merge entry { is-revealed: true })
                    )
                    (ok true)
                )
                (ok false)
            )
        )
    )
)

(define-public (get-reflection-count (author principal))
    (begin
        (asserts! (validate-author author) err-invalid-author)
        (ok (get-reflection-count-internal author))
    )
)

(define-public (get-public-reflections-by-category (category (string-utf8 32)))
    (begin
        (asserts! (validate-category category) err-invalid-category)
        (ok (default-to (list) (map-get? category-index {category: category})))
    )
)

(define-public (add-category-to-index (reflection-id uint) (category (string-utf8 32)))
    (begin
        (asserts! (validate-category category) err-invalid-category)
        (let (
            (current-entries (default-to (list) (map-get? category-index {category: category})))
            (new-entry {reflection-id: reflection-id, author: tx-sender})
        )
            (if (< (len current-entries) u50)
                (begin
                    (map-set category-index 
                        {category: category}
                        (unwrap! (as-max-len? (concat current-entries (list new-entry)) u50)
                                err-category-full))
                    (ok true))
                err-category-full)
        )
    )
)