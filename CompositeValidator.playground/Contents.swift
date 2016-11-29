//: Playground - noun: a place where people can play

import UIKit

/*
 Original example taken from here: http://hotcocoatouch.com/2016/11/16/composite-validators/
 
 We'll use Functional Swift book to build functional version of composite validator
 */

// MARK: - Constants for testing

let emptyEmail = ""
let invalidEmail = "invalidEmail@"
let validEmail = "validEmail@validDomain.com"
let emptyPassword = ""
let tooShortPassword = "pa$$"
let passwordWithNoUppercase = "passw0rd"
let validPassword = "paSSw0rd"

// MAKR: - Original validators

enum ValidatorResult1 {
    case valid
    case invalid(error: Error)
}

protocol Validator1 {
    func validate(string: String) -> ValidatorResult1
}

enum EmailValidatorError: Error {
    case empty
    case invalidFormat
}

enum PasswordValidatorError: Error {
    case empty
    case tooShort
    case noUppercaseLetter
    case noLowercaseLetter
    case noNumber
}

struct EmptyStringValidator: Validator1 {

    // This error is passed via the initializer to allow this validator to be reused
    private let invalidError: Error

    init(invalidError: Error) {
        self.invalidError = invalidError
    }

    func validate(string: String) -> ValidatorResult1 {
        return string.isEmpty ? .invalid(error: invalidError) : .valid
    }

}

struct EmailFormatValidator: Validator1 {

    func validate(string: String) -> ValidatorResult1 {
        let magicEmailRegexStolenFromTheInternet = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", magicEmailRegexStolenFromTheInternet)
        return emailTest.evaluate(with: string) ? .valid : .invalid(error: EmailValidatorError.invalidFormat)
    }

}

struct PasswordLengthValidator: Validator1 {

    func validate(string: String) -> ValidatorResult1 {
        return string.characters.count >= 8 ? .valid : .invalid(error: PasswordValidatorError.tooShort)
    }

}

struct UppercaseLetterValidator: Validator1 {

    func validate(string: String) -> ValidatorResult1 {
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        return uppercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noUppercaseLetter)
    }
    
}

struct LowercaseLetterValidator: Validator1 {

    func validate(string: String) -> ValidatorResult1 {
        let lowercaseLetterRegex = ".*[a-z]+.*"
        let lowercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", lowercaseLetterRegex)
        return lowercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noLowercaseLetter)
    }
    
}

struct ContainsNumberValidator: Validator1 {

    func validate(string: String) -> ValidatorResult1 {
        let containsNumberRegex = ".*[0-9]+.*"
        let containsNumberTest = NSPredicate(format: "SELF MATCHES %@", containsNumberRegex)
        return containsNumberTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noNumber)
    }

}

struct CompositeValidator: Validator1 {

    private let validators: [Validator1]

    init(validators: [Validator1]) {
        self.validators = validators
    }

    func validate(string: String) -> ValidatorResult1 {
        for validator in validators {
            switch validator.validate(string: string) {
            case .invalid(let error):
                return .invalid(error: error)
            case .valid:
                break
            }
        }
        return .valid
    }

}

struct ValidatorConfigurator1 {

    static func emailValidator() -> Validator1 {
        let validators: [Validator1] = [emptyEmailStringValidator(), EmailFormatValidator()]
        return CompositeValidator(validators: validators)
    }

    static func passwordValidator() -> Validator1 {
        let validators: [Validator1] = [emptyPasswordStringValidator(), passwordStrengthValidator()]
        return CompositeValidator(validators: validators)
    }

    // MAKR: Private

    private static func emptyEmailStringValidator() -> Validator1 {
        return EmptyStringValidator(invalidError: EmailValidatorError.empty)
    }

    private static func emptyPasswordStringValidator() -> Validator1 {
        return EmptyStringValidator(invalidError: PasswordValidatorError.empty)
    }

    private static func passwordStrengthValidator() -> Validator1 {
        let validators: [Validator1] = [PasswordLengthValidator(),
                                       UppercaseLetterValidator(),
                                       LowercaseLetterValidator(),
                                       PasswordLengthValidator()]
        return CompositeValidator(validators: validators)
    }

}

// MARK: - Testing

let emailValidator1 = ValidatorConfigurator1.emailValidator()
let passwordValidator1 = ValidatorConfigurator1.passwordValidator()

print(emailValidator1.validate(string: emptyEmail))
print(emailValidator1.validate(string: invalidEmail))
print(emailValidator1.validate(string: validEmail))

print(passwordValidator1.validate(string: emptyPassword))
print(passwordValidator1.validate(string: tooShortPassword))
print(passwordValidator1.validate(string: passwordWithNoUppercase))
print(passwordValidator1.validate(string: validPassword))

// MARK: - Functional validators

enum ValidatorResult2 {
    case valid
    case invalid(error: Error)

    // TODO: rename
    func compose(_ validatorResult: ValidatorResult2) -> ValidatorResult2 {
        switch (self, validatorResult) {
        case (.valid, .valid):
            return .valid
        case (.invalid(let error), _):
            return .invalid(error: error)
        case (_, .invalid(let error)):
            return .invalid(error: error)
        default:
            return .valid // just for testing
        }
    }
}

typealias Validator2 = (String) -> ValidatorResult2

func compose(val1: @escaping Validator2, val2: @escaping Validator2) -> Validator2 {
    return { string in val1(string).compose(val2(string)) }
}

func emptyStringValidator(error: Error) -> Validator2 {
    return { string in string.isEmpty ? .invalid(error: error) : .valid }
}

func emptyEmailStringValidator() -> Validator2 {
    return emptyStringValidator(error: EmailValidatorError.empty)
}

func emptyPasswordValidator() -> Validator2 {
    return emptyStringValidator(error: PasswordValidatorError.empty)
}

func emailFormatValidator() -> Validator2 {
    return { string in
        let magicEmailRegexStolenFromTheInternet = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", magicEmailRegexStolenFromTheInternet)
        return emailTest.evaluate(with: string) ? .valid : .invalid(error: EmailValidatorError.invalidFormat)
    }
}

func passwordLengthValidator() -> Validator2 {
    return { string in string.characters.count >= 8 ? .valid : .invalid(error: PasswordValidatorError.tooShort) }
}

func passwordUppercaseValidator() -> Validator2 {
    return { string in
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        return uppercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noUppercaseLetter)
    }
}

func passwordLowercaseValidator() -> Validator2 {
    return { string in
        let lowercaseLetterRegex = ".*[a-z]+.*"
        let lowercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", lowercaseLetterRegex)
        return lowercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noLowercaseLetter)
    }
}

func containsNumberValidator() -> Validator2 {
    return { string in
        let containsNumberRegex = ".*[0-9]+.*"
        let containsNumberTest = NSPredicate(format: "SELF MATCHES %@", containsNumberRegex)
        return containsNumberTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noNumber)
    }
}

func &(_ validator1: @escaping Validator2, _ validator2: @escaping Validator2) -> Validator2 {
    return { string in validator1(string).compose(validator2(string)) }
}

struct ValidatorConfigurator2 {

    static func emailValidator() -> Validator2 {
        return emptyEmailStringValidator() & emailFormatValidator()
    }

    static func passwordValidator() -> Validator2 {
        return emptyPasswordValidator() & passwordLengthValidator() & passwordUppercaseValidator() & passwordLowercaseValidator() & containsNumberValidator()
    }

}

// MARK: - Testing

let emailValidator2 = ValidatorConfigurator2.emailValidator()
print(emailValidator2(emptyEmail))
print(emailValidator2(invalidEmail))
print(emailValidator2(validEmail))

let passwordValidator2 = ValidatorConfigurator2.passwordValidator()
print(passwordValidator2(emptyPassword))
print(passwordValidator2(tooShortPassword))
print(passwordValidator2(passwordWithNoUppercase))
print(passwordValidator2(validPassword))

